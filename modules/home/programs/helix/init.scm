(require "plugins/vim-hx/init.scm")
(require "steel-pty/term.scm")
(set-default-shell! "fish")
(set-vim-keybindings!)
(require "vim-hx-additions/paragraph-delete.scm")
(set-paragraph-delete-keybindings!)
(require "vim-hx-additions/vim-fixes.scm")
(set-vim-fix-keybindings!)
(require "vim-hx-additions/vim-repeat-find.scm")
(set-vim-repeat-find-keybindings!)
(require "plugins/wakatime/wakatime.scm")
(require "forest/forest.scm")
;; forest.hx recurses into every directory via read-dir, following symlinks.
;; Nix repos have `result` -> /nix/store/.../<full system closure> and
;; `.devenv/{profile,bash,run}` -> /nix/store/... symlinks; walking those
;; traverses the entire NixOS closure and hangs the editor on space+e.
;; forest-configure! REPLACES the ignore set, so list every default too.
(forest-configure! 'left #:ignore (list ".git" "target" ".direnv" ".devenv" "node_modules" "__pycache__" ".hg" "result"))
(require "helix-file-watcher/file-watcher.scm")
(spawn-watcher 2000)
(require "theme-picker/theme-picker.scm")
