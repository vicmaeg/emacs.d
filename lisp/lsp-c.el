;;; lsp-c.el --- C LSP configuration (lsp-mode + clangd) -*- lexical-binding: t; -*-

;; clangd needs a compile_commands.json (or a .clangd YAML) in the
;; project root to resolve includes correctly.
;;
;; For GStreamer projects built with Meson the typical workflow is:
;;
;;   meson setup builddir
;;   meson compile -C builddir            # builds the project
;;   ln -sf builddir/compile_commands.json .   # or let clangd find it
;;
;; Alternatively "bear -- meson compile -C builddir" will capture
;; compiler flags that Meson's own JSON may miss (e.g. generated
;; sources).
;;
;; You can also place a .clangd file in the project root:
;;
;;   CompileFlags:
;;     Add:
;;       - "-I/usr/include/gstreamer-1.0"
;;       - "-I/usr/include/glib-2.0"
;;       - "-I/usr/lib/x86_64-linux-gnu/glib-2.0/include"
;;
;; Run "pkg-config --cflags gstreamer-1.0" to get the right paths
;; for your system.

;;; Code

(add-hook 'c-mode-hook #'lsp-deferred)
(add-hook 'c-ts-mode-hook #'lsp-deferred)
(add-hook 'c-mode-hook #'flymake-mode)
(add-hook 'c-ts-mode-hook #'flymake-mode)

(provide 'lsp-c)
;;; lsp-c.el ends here