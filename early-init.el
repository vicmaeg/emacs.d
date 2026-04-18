(setq inhibit-startup-screen t)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;;; Set paths for both emacs and external emacs processes
(add-to-list 'exec-path "~/.dotnet/tools/")
(setenv "PATH" (concat "~/.dotnet/tools/:" (getenv "PATH")))
(add-to-list 'exec-path "~/.local/bin/")
(setenv "PATH" (concat "~/.local/bin/:" (getenv "PATH")))
(add-to-list 'exec-path "~/.opencode/bin/")
(setenv "PATH" (concat "~/.opencode/bin/:" (getenv "PATH")))

;;; Performance: assume left-to-right text everywhere and skip bidirectional
;;; parenthesis algorithm — avoids unnecessary work on every redisplay cycle
;;; when you don't edit right-to-left languages
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)
