(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;;; Set paths for both emacs and external emacs processes
(add-to-list 'exec-path "/home/vicmaeg/.dotnet/tools/")
(setenv "PATH" (concat "/home/vicmaeg/.dotnet/tools/:" (getenv "PATH")))
