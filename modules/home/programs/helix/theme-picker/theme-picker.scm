(require "helix/components.scm")
(require "helix/themes.scm")
(require "helix/editor.scm")
(require (prefix-in helix. "helix/commands.scm"))
(require "microscope/microscope.scm")

(provide theme-picker-open)

;; Built-in fallback theme list in case themes->list is unavailable
(define *tp-fallback-themes*
  (list "adwaita-dark" "adwaita-light" "amberwood" "autumn" "autumn_night" "ayuccin" "ayu_dark"
        "ayu_evolve" "ayu_light" "ayu_mirage" "base16_default_dark" "base16_default_light"
        "base16_terminal" "base16_transparent" "bogster" "bogster_light" "boo" "catppuccin_frappe"
        "catppuccin_latte" "catppuccin_macchiato" "catppuccin_mocha" "chadracula" "chameleon"
        "curator" "cyan_light" "dark_high_contrast" "dark_plus" "default" "dracula" "dracula_at_night"
        "doom_acario_dark" "emacs" "everforest_dark" "everforest_light" "everforest_transparent"
        "ferrum" "flatwhite" "fleet_dark" "github_dark" "github_dark_colorblind" "github_dark_dimmed"
        "github_dark_high_contrast" "github_light" "github_light_colorblind" "github_light_high_contrast"
        "glaucoma" "gruvbox" "gruvbox_dark_hard" "gruvbox_dark_soft" "gruvbox_light"
        "gruvbox_light_hard" "gruvbox_light_soft" "hex_steel" "horizon_dark" "insubstantial"
        "kaolin_dark" "kaolin_light" "kanagawa" "kanagawa_dragon" "kanagawa_lotus" "laserwave"
        "monokai" "monokai_aqua" "monokai_pro" "nightfox" "nord" "nord_light" "nord_transparent"
        "onedark" "onelight" "papercolor-dark" "papercolor-light" "pop-dark" "rose_pine"
        "rose_pine_dawn" "rose_pine_moon" "serika_dark" "solarized_dark" "solarized_light"
        "sonokai" "spacebones_light" "stylix" "terafox" "term16_dark" "term16_light" "tokyonight"
        "tokyonight_day" "tokyonight_moon" "tokyonight_storm" "vesper" "zenburn"))

;; Loaded once at startup; the editor's own require chain runs before any
;; command dispatch touches the editor context, so this is a cheap, safe
;; place to enumerate themes exactly once.
(define *tp-all-themes*
  (let ([loaded (with-handler (lambda (_) '()) (themes->list))])
    (if (and (list? loaded) (not (null? loaded)))
        (sort loaded string<?)
        *tp-fallback-themes*)))

;; Subsequence fuzzy matching (Telescope / fzf style)
(define (tp-fuzzy-match? q-chars str)
  (define s-chars (string->list (string-downcase str)))
  (let loop ([qc q-chars] [sc s-chars])
    (cond
      [(null? qc) #t]
      [(null? sc) #f]
      [(char=? (car qc) (car sc)) (loop (cdr qc) (cdr sc))]
      [else (loop qc (cdr sc))])))

;; fetch: pure filter over the pre-loaded theme list, no side effects
(define (tp-fetch query state)
  (if (string=? query "")
      *tp-all-themes*
      (let ([q-chars (string->list (string-downcase query))])
        (filter (lambda (name) (tp-fuzzy-match? q-chars name)) *tp-all-themes*))))

;; show: render a theme name as a picker row
(define (tp-show item width)
  (Line (list item) (list)))

;; on-select: Enter applies the chosen theme and closes the picker
(define (tp-on-select item state)
  (with-handler (lambda (_) void) (helix.theme item))
  (cons event-result/close state))

(define (theme-picker-open)
  (microscope (Picker tp-fetch tp-show tp-on-select #f)))
