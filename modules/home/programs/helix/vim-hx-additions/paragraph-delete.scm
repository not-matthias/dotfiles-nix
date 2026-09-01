;; d} / d{ — cut from the cursor to the next/previous paragraph boundary.
;;
;; vim.hx registers the paragraph text-objects (dap/dip) and the bare
;; {/} jumps, but nothing under the `d` operator targets a paragraph
;; boundary. These mirror Vim's d}/d{: yank + delete the range the {/}
;; motion crosses.
;;
;; `goto_next_paragraph` only *moves* the cursor in normal mode, so we
;; capture the position before/after the jump and extend the selection
;; explicitly — the same pattern as vim.hx's vim-delete-prev-word.

(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")
(require "helix/misc.scm")
(require "helix/keymaps.scm")
(require "plugins/vim-hx/utils.scm")

;; d}
(define (vim-delete-to-next-paragraph)
  (define pos (cursor-position))
  (helix.static.goto_next_paragraph)
  (define end-pos (cursor-position))
  (when (not (equal? end-pos pos))
    (move-to-position pos)
    (extend-to-position end-pos)
    (helix.clipboard-yank)
    (helix.static.delete_selection)))

;; d{
(define (vim-delete-to-prev-paragraph)
  (define pos (cursor-position))
  (helix.static.goto_prev_paragraph)
  (define start-pos (cursor-position))
  (when (not (equal? start-pos pos))
    (move-to-position start-pos)
    (extend-to-position pos)
    (helix.clipboard-yank)
    (helix.static.delete_selection)))

;; Merges `}` and `{` into the `d` prefix node that set-vim-keybindings!
;; registered. add-global-keybinding merges recursively, so the
;; dd/dw/dap/... bindings are left intact. Must run after that call.
(define (set-paragraph-delete-keybindings!)
  (add-global-keybinding
    (keymap (normal (d ("}" ":vim-delete-to-next-paragraph")
                       ("{" ":vim-delete-to-prev-paragraph"))))))

(provide vim-delete-to-next-paragraph
         vim-delete-to-prev-paragraph
         set-paragraph-delete-keybindings!)
