(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;;; Set paths for both emacs and external emacs processes
(add-to-list 'exec-path "/home/vicmaeg/.dotnet/tools/")
(setenv "PATH" (concat "/home/vicmaeg/.dotnet/tools/:" (getenv "PATH")))
(add-to-list 'exec-path "/home/vmartos/.dotnet/tools/")
(setenv "PATH" (concat "/home/vmartos/.dotnet/tools/:" (getenv "PATH")))
(add-to-list 'exec-path "/home/vmartos/.local/bin/")
(setenv "PATH" (concat "/home/vmartos/.local/bin/:" (getenv "PATH")))
