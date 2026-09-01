(require "helix/keymaps.scm")

(define (set-vim-repeat-find-keybindings!)
  (add-global-keybinding
    (keymap
      (normal
        ("," ":vim-reverse-last-find")
        (";" ":vim-repeat-last-find"))
      (select
        ("," ":select-reverse-last-find")
        (";" ":select-repeat-last-find")))))

(provide set-vim-repeat-find-keybindings!)
