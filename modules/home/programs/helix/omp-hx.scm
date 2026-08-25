;;; omp-hx.scm — Helix (steelix) plugin for oh-my-pi (omp)
;;;
;;; Communicates with the omp editor bridge over a per-cwd Unix socket via socat.
;;; Injects prompts, expands @buffer and @this placeholders, sends selections,
;;; and reloads modified files when an omp turn finishes.

(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require-builtin helix/core/text as text.)
(require "helix/editor.scm")
(require "helix/ext.scm")
(require "helix/misc.scm")
(require "helix/keymaps.scm")
(require-builtin steel/process)
(require-builtin steel/ports)
(require-builtin steel/json)
(require-builtin steel/meta)
(require-builtin steel/time)
(require-builtin steel/filesystem)

;; ---------------------------------------------------------------------------
;; Global State & Socket Discovery
;; ---------------------------------------------------------------------------

(define *omp-conn* #f)
(define *omp-chat-path* #f)
(define *omp-chat-text* "")
(define *omp-chat-stream-open?* #f)
(define *omp-last-code-doc-id* #f)
(define *omp-last-code-line* 1)

(define (omp-connected?)
  (and *omp-conn* #t))

(define (omp-socket-dir)
  (string-append (env-var "HOME") "/.omp/run/omp-helix"))

(define (omp-cwd)
  (current-directory))

;; One-shot sha256 subprocess to compute the 16-hex-character directory hash
(define (sha256-16 s)
  (let* ([proc (~> (command "sha256sum" '())
                   with-stdin-piped
                   with-stdout-piped
                   spawn-process)]
         [child (Ok->value proc)]
         [stdin-p (child-stdin child)]
         [stdout-p (child-stdout child)])
    (display s stdin-p)
    (flush-output-port stdin-p)
    (close-output-port stdin-p)
    (let ([line (read-line-from-port stdout-p)])
      (if (and (string? line) (>= (string-length line) 16))
          (substring line 0 16)
          ""))))

(define (omp-socket-path)
  (let* ([dir (omp-socket-dir)]
         [cwd (omp-cwd)]
         [hash (sha256-16 cwd)])
    (string-append dir "/omp-helix-" hash ".sock")))
;; Document Reloading
;; ---------------------------------------------------------------------------

(define (omp-reload-changed!)
  (for-each
   (lambda (doc-id)
     (let* ([path (with-handler (lambda (_) #f) (editor-document->path doc-id))]
            [metadata (and (string? path)
                           (path-exists? path)
                           (with-handler (lambda (_) #f) (file-metadata path)))]
            [last-saved (with-handler (lambda (_) #f)
                          (editor-document-last-saved doc-id))])
       (when (and metadata
                  last-saved
                  (not (with-handler (lambda (_) #t)
                         (editor-document-dirty? doc-id)))
                  (system-time>? (fs-metadata-modified metadata) last-saved))
         (with-handler (lambda (_) #f)
           (editor-document-reload doc-id)))))
   (editor-all-documents)))

;; ---------------------------------------------------------------------------
;; Chat Panel
;; ---------------------------------------------------------------------------

(define (omp-chat-file-path)
  (or *omp-chat-path*
      (begin
        (set! *omp-chat-path*
              (string-append "/tmp/omp-hx-chat-" (sha256-16 (omp-cwd)) ".md"))
        *omp-chat-path*)))

(define (omp-chat-document-id)
  (let loop ([doc-ids (editor-all-documents)])
    (if (null? doc-ids)
        #f
        (let* ([doc-id (car doc-ids)]
               [path (with-handler (lambda (_) #f)
                       (editor-document->path doc-id))])
          (if (and (string? path) (string=? path (omp-chat-file-path)))
              doc-id
              (loop (cdr doc-ids)))))))

(define (omp-chat-write!)
  (call-with-output-file
   (omp-chat-file-path)
   (lambda (port) (display *omp-chat-text* port))
   #:exists 'truncate))

(define (omp-chat-refresh!)
  (when (omp-chat-focused?)
    (with-handler (lambda (_) #f)
      (helix.reload))))
(define (omp-remember-code-focus!)
  (let* ([focus (editor-focus)]
         [doc-id (editor->doc-id focus)]
         [path (with-handler (lambda (_) #f)
                 (editor-document->path doc-id))])
    (when (and (string? path)
               (not (string=? path (omp-chat-file-path))))
      (set! *omp-last-code-doc-id* doc-id)
      (set! *omp-last-code-line*
            (with-handler (lambda (_) 1)
              (helix.static.get-current-line-number))))))

(define (omp-chat-open!)
  (omp-remember-code-focus!)
  (let ([path (omp-chat-file-path)])
    (if (omp-chat-document-id)
        #f
        (begin
          (omp-chat-write!)
          (helix.vsplit path)))))

(define (omp-chat-append! text)
  (when (string? text)
    (set! *omp-chat-text* (string-append *omp-chat-text* text))
    (omp-chat-write!)))

(define (omp-chat-handle-frame frame)
  (let ([type (if (and (hash? frame) (hash-contains? frame 'type))
                  (hash-get frame 'type)
                  #f)])
    (cond
      [(equal? type "chat_user")
       (begin
         (unless (omp-chat-document-id)
           (omp-chat-open!))
         (set! *omp-chat-stream-open?* #t)
         (omp-chat-append!
          (string-append "\n\n### You\n\n"
                         (hash-get frame 'text)
                         "\n\n### omp\n\n")))]
      [(equal? type "chat_delta")
       (begin
         (unless *omp-chat-stream-open?*
           (begin
             (unless (omp-chat-document-id)
               (omp-chat-open!))
             (set! *omp-chat-stream-open?* #t)
             (omp-chat-append! "\n\n### omp\n\n")))
         (omp-chat-append! (hash-get frame 'text)))]
      [(equal? type "chat_tool")
       (omp-chat-append!
        (string-append "\n\n> tool: " (hash-get frame 'name) "\n\n"))]
      [(equal? type "chat_message_end")
       (begin
         (set! *omp-chat-stream-open?* #f)
         (omp-chat-append! "\n")
         (omp-chat-refresh!))]
      [else #f])))
;; Event Handling
;; ---------------------------------------------------------------------------

(define (omp-handle-event frame)
  (let ([event (if (and (hash? frame) (hash-contains? frame 'event)) (hash-get frame 'event) #f)]
        [type (if (and (hash? frame) (hash-contains? frame 'type)) (hash-get frame 'type) #f)])
    (cond
      [(equal? type "pong")
       (set-status! "omp: bridge alive")]
      [(equal? event "ready")
       (set-status! "omp: bridge connected")]
      [(equal? event "prompt_accepted")
       (set-status! "omp: prompt sent")]
      [(equal? event "turn_started")
       (set-status! "omp: working…")]
      [(equal? event "turn_ended")
       (begin
         (set-status! "omp: done")
         (omp-reload-changed!))]
      [(or (equal? type "chat_user")
           (equal? type "chat_delta")
           (equal? type "chat_tool")
           (equal? type "chat_message_end"))
       (omp-chat-handle-frame frame)]
      [else #f])))

;; ---------------------------------------------------------------------------
;; Connection Management
;; ---------------------------------------------------------------------------

(define (omp-connect!)
  (if (omp-connected?)
      #t
      (let ([sock (omp-socket-path)])
        (if (not (path-exists? sock))
            (begin
              (set-error! "omp-hx: no omp bridge in this directory (start omp here first)")
              #f)
            (let ([proc (~> (command "socat" (list "-" (string-append "UNIX-CONNECT:" sock)))
                            with-stdin-piped
                            with-stdout-piped
                            spawn-process)])
              (if (not (Ok? proc))
                  (begin
                    (set-error! "omp-hx: failed to spawn socat")
                    #f)
                  (let* ([child (Ok->value proc)]
                         [stdin-p (child-stdin child)]
                         [stdout-p (child-stdout child)])
                    (set! *omp-conn* (hash "proc" child "stdin-p" stdin-p "stdout-p" stdout-p))
                    (spawn-native-thread
                     (lambda ()
                       (let loop ()
                         (let ([line (with-handler (lambda (_) #f) (read-line-from-port stdout-p))])
                           (when (and (string? line) (not (string=? line "")))
                             (let ([frame (with-handler (lambda (_) #f) (string->jsexpr line))])
                               (when frame
                                 (hx.with-context
                                  (lambda ()
                                    (enqueue-thread-local-callback-with-delay
                                     0
                                     (lambda () (omp-handle-event frame)))))))
                             (loop))))
                       (hx.with-context
                        (lambda ()
                          (enqueue-thread-local-callback-with-delay
                           0
                           (lambda ()
                             (set! *omp-conn* #f)
                             (set-warning! "omp-hx: bridge connection closed")))))))
                    #t)))))))

(define (omp-disconnect)
  (when *omp-conn*
    (let ([proc (hash-get *omp-conn* "proc")])
      (with-handler (lambda (_) #f) (subprocess-kill proc))
      (set! *omp-conn* #f)
      (set-status! "omp: disconnected"))))

;; ---------------------------------------------------------------------------
;; Message Sending & Placeholder Resolution
;; ---------------------------------------------------------------------------

(define (omp-send! text submit?)
  (let ([connected? (or (omp-connected?) (omp-connect!))])
    (if (not connected?)
        #f
        (let* ([conn *omp-conn*]
               [stdin-p (hash-get conn "stdin-p")]
               [frame (hash "type" "prompt" "text" text "submit" submit?)]
               [payload (string-append (value->jsexpr-string frame) "\n")])
          (with-handler
            (lambda (err)
              (set! *omp-conn* #f)
              (set-error! (string-append "omp-hx: send failed: " (to-string err))))
            (display payload stdin-p)
            (flush-output-port stdin-p))))))

(define (omp-get-current-file-reference)
  (let* ([focus (editor-focus)]
         [doc-id (editor->doc-id focus)]
         [path (with-handler (lambda (_) #f) (editor-document->path doc-id))])
    (if (or (not (string? path)) (string=? path ""))
        ;; Unnamed / scratch buffer
        #f
        (let ([is-dirty? (with-handler (lambda (_) #f) (editor-document-dirty? doc-id))])
          (if is-dirty?
              (let ([snap (string-append "/tmp/omp-hx-snap-" (to-string (doc-id->usize doc-id)) ".txt")]
                    [content (text.rope->string (editor->text doc-id))])
                (with-handler (lambda (_) path)
                  (call-with-output-file snap (lambda (p) (display content p)) #:exists 'truncate)
                  snap))
              path)))))

(define (omp-get-current-location-reference)
  (let* ([file-ref (omp-get-current-file-reference)])
    (if (not file-ref)
        ""
        (let* ([focus (editor-focus)]
               [doc-id (editor->doc-id focus)]
               [rope (editor->text doc-id)]
               [sel (helix.static.current-selection-object)]
               [range (helix.static.selection->primary-range sel)]
               [from-offset (helix.static.range->from range)]
               [to-offset (helix.static.range->to range)]
               [start-offset (min from-offset to-offset)]
               [end-offset (max from-offset to-offset)]
               [start-line (+ 1 (text.rope-char->line rope start-offset))]
               [end-line (+ 1 (text.rope-char->line rope end-offset))])
          (if (= from-offset to-offset)
              (string-append "@" file-ref)
              (string-append "@" file-ref ":"
                             (int->string start-line)
                             "-"
                             (int->string end-line)))))))

(define (omp-resolve-placeholders text)
  (let* ([loc-ref (omp-get-current-location-reference)]
         [file-ref (omp-get-current-file-reference)]
         [buf-ref (if file-ref (string-append "@" file-ref) "")]
         [res-this (if (string-contains? text "@this")
                       (string-replace text "@this" loc-ref)
                       text)]
         [res-buf (if (string-contains? res-this "@buffer")
                      (string-replace res-this "@buffer" buf-ref)
                      res-this)])
    res-buf))

;; ---------------------------------------------------------------------------
;; Interactive Commands
;; ---------------------------------------------------------------------------

;;@doc
;; Send a prompt to the omp agent in the current workspace directory.
(define (omp-ask)
  (push-component!
   (prompt "omp: "
           (lambda (input)
             (when (and (string? input) (not (string=? input "")))
               (omp-send! (omp-resolve-placeholders input) #t))))))

;;@doc
;; Open the persistent right-side chat buffer.
(define (omp-chat-open)
  (omp-chat-open!))

;;@doc
;; Open the chat buffer and send a prompt through the omp session.
(define (omp-chat-ask)
  (omp-chat-open!)
  (push-component!
   (prompt "omp chat: "
           (lambda (input)
             (when (and (string? input) (not (string=? input "")))
               (omp-send! (omp-resolve-placeholders input) #t))))))

(define (omp-chat-focused?)
  (let* ([focus (editor-focus)]
         [doc-id (editor->doc-id focus)]
         [path (with-handler (lambda (_) #f)
                 (editor-document->path doc-id))])
    (and (string? path) (string=? path (omp-chat-file-path)))))

(define (omp-line-context-for doc-id line-number)
  (let ([rope (editor->text doc-id)])
    (text.rope->string
     (text.rope->line rope (max 0 (- line-number 1))))))

(define (omp-current-line-context)
  (if (and (omp-chat-focused?) *omp-last-code-doc-id*)
      (omp-line-context-for *omp-last-code-doc-id* *omp-last-code-line*)
      (let* ([focus (editor-focus)]
             [doc-id (editor->doc-id focus)]
             [line-number (helix.static.get-current-line-number)])
        (omp-line-context-for doc-id line-number))))

(define (omp-quick-location-reference)
  (if (and (omp-chat-focused?) *omp-last-code-doc-id*)
      (let ([path (editor-document->path *omp-last-code-doc-id*)])
        (string-append "@"
                       path
                       ":"
                       (int->string *omp-last-code-line*)
                       "-"
                       (int->string *omp-last-code-line*)))
      (omp-get-current-location-reference)))

;;@doc
;; Ask omp to act on the current selection, or the current line.
(define (omp-quick-chat)
  (let* ([selection (if (omp-chat-focused?)
                        ""
                        (helix.static.current-selection->string))]
         [context (if (string=? selection "")
                      (omp-current-line-context)
                      selection)]
         [location (omp-quick-location-reference)])
    (omp-chat-open!)
    (push-component!
     (prompt "omp quick chat: "
             (lambda (input)
               (when (and (string? input) (not (string=? input "")))
                 (omp-send!
                  (string-append
                   "Use the following editor context and apply the requested change "
                   "directly through your normal tools.\n\n"
                   location
                   "\n\n```text\n"
                   context
                   "\n```\n\n"
                   input)
                  #t)))))))

;;@doc
;; Fill the omp agent's input editor with a prompt without auto-submitting.
(define (omp-ask-hold)
  (omp-chat-open!)
  (push-component!
   (prompt "omp (hold): "
           (lambda (input)
             (when (and (string? input) (not (string=? input "")))
               (omp-send! (omp-resolve-placeholders input) #f))))))

;;@doc
;; Send the active selection and file reference to the omp agent and run it.
(define (omp-send-selection)
  (let ([sel (helix.static.current-selection->string)]
        [loc-ref (omp-get-current-location-reference)])
    (omp-chat-open!)
    (if (string=? sel "")
        (set-warning! "omp-hx: no selection")
        (let ([msg (if (not (string=? loc-ref ""))
                       (string-append loc-ref "\n\n" sel)
                       sel)])
          (omp-send! msg #t)))))

;;@doc
;; Send the active selection to the omp input editor without auto-submitting.
(define (omp-send-selection-hold)
  (let ([sel (helix.static.current-selection->string)]
        [loc-ref (omp-get-current-location-reference)])
    (omp-chat-open!)
    (if (string=? sel "")
        (set-warning! "omp-hx: no selection")
        (let ([msg (if (not (string=? loc-ref ""))
                       (string-append loc-ref "\n\n" sel)
                       sel)])
          (omp-send! msg #f)))))

;;@doc
;; Ping the omp editor bridge to verify connectivity.
(define (omp-ping)
  (let ([connected? (or (omp-connected?) (omp-connect!))])
    (when connected?
      (let* ([conn *omp-conn*]
             [stdin-p (hash-get conn "stdin-p")]
             [frame (hash "type" "ping")]
             [payload (string-append (value->jsexpr-string frame) "\n")])
        (with-handler
          (lambda (err)
            (set! *omp-conn* #f)
            (set-error! (string-append "omp-hx: ping failed: " (to-string err))))
          (display payload stdin-p)
          (flush-output-port stdin-p))))))

;; ---------------------------------------------------------------------------
;; Keybindings Setup
;; ---------------------------------------------------------------------------

(define *omp-normal-keybindings*
  (hash
   "c" ":omp-chat-open"
   "a" ":omp-chat-ask"
   "q" ":omp-quick-chat"
   "A" ":omp-ask-hold"
   "s" ":omp-send-selection"
   "S" ":omp-send-selection-hold"))

(define *omp-select-keybindings*
  (hash
   "c" ":omp-chat-open"
   "q" ":omp-quick-chat"
   "s" ":omp-send-selection"
   "S" ":omp-send-selection-hold"))

(define *omp-keybindings*
  (hash
   "normal" (hash "space" (hash "o" *omp-normal-keybindings*))
   "select" (hash "space" (hash "o" *omp-select-keybindings*))))

(define (set-omp-keybindings!)
  (add-global-keybinding *omp-keybindings*))

(provide omp-ask
         omp-chat-open
         omp-chat-ask
         omp-quick-chat
         omp-ask-hold
         omp-send-selection
         omp-send-selection-hold
         omp-ping
         omp-disconnect
         set-omp-keybindings!)
