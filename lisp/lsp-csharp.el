;;; lsp-csharp.el --- C# LSP configuration (lsp-mode + roslyn) -*- lexical-binding: t; -*-

;; Pull diagnostics for C# via roslyn LSP.
;;
;; The roslyn language server uses pull diagnostics (LSP 3.17+
;; `textDocument/diagnostic') instead of push diagnostics.
;; lsp-mode sends `:json-false' for `diagnostic.dynamicRegistration'
;; and `diagnostics.refreshSupport' by default, so we patch those to
;; `t' via `lsp-csharp--patch-capabilities'.
;;
;; After installing or upgrading lsp-mode, recompile it with plist
;; support so that macro expansions in lsp-protocol.el use plist-get
;; instead of gethash.  Without this the running code will still call
;; hash-table-p on plist data and signal wrong-type-argument.
;;
;;   emacs --batch --eval '(progn \
;;     (setenv "LSP_USE_PLISTS" "true") \
;;     (setq lsp-use-plists t) \
;;     (let ((default-directory (expand-file-name "elpa" user-emacs-directory))) \
;;       (normal-top-level-add-subdirs-to-load-path)) \
;;     (byte-recompile-directory \
;;       (expand-file-name "elpa/lsp-mode-<VERSION>" user-emacs-directory) 0 t))'

;;; Code

(require 'lsp-mode)
(require 'lsp-roslyn)

(defun lsp-csharp--maybe-start-lsp ()
  "Start LSP for C# files, but skip decompiled metadata sources.
Roslyn stores decompiled framework files under a system temp directory
(e.g. /tmp/MetadataAsSource/<uuid>/...).  Opening them should not
trigger a workspace-root prompt or a new LSP session."
  (unless (and buffer-file-name
               (string-match-p "MetadataAsSource" buffer-file-name))
    (lsp-deferred)))

(add-hook 'csharp-ts-mode-hook #'lsp-deferred)
(add-hook 'csharp-ts-mode-hook #'flymake-mode)
(add-hook 'csharp-ts-mode-hook #'electric-pair-local-mode)

(setq lsp-roslyn-server-log-level "Warning")

(defun lsp-csharp--patch-capabilities (caps)
  "Patch CAPS to enable pull diagnostics for roslyn.
 lsp-mode defaults to `:json-false' for two capability keys that roslyn
 requires: `textDocument.diagnostic.dynamicRegistration' and
 `workspace.diagnostics.refreshSupport'.  This flips them to `t'.
 CAPS is always an alist regardless of `lsp-use-plists'."
  (setcdr (assoc 'diagnostics (cdr (assoc 'workspace caps)))
          '((refreshSupport . t)))
  (setcdr (assoc 'diagnostic (cdr (assoc 'textDocument caps)))
          '((dynamicRegistration . t) (relatedDocumentSupport . t)))
  caps)

(advice-add 'lsp--client-capabilities :filter-return
            #'lsp-csharp--patch-capabilities)

(defun lsp-csharp--roslyn-stdio-command ()
  "Return the command to start roslyn-language-server via stdio.
Assumes the tool was installed with:
  dotnet tool install -g roslyn-language-server --prerelease"
  (list "roslyn-language-server"
        "--stdio"
        "--logLevel" lsp-roslyn-server-log-level
        "--clientProcessId" (number-to-string (emacs-pid))
        "--autoLoadProjects"))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection #'lsp-csharp--roslyn-stdio-command)
                  :priority 1
                  :server-id 'roslyn-language-server
                  :activation-fn (lsp-activate-on "csharp")
                  :path->uri-fn #'lsp-roslyn--path-to-uri
                  :uri->path-fn #'lsp-roslyn--uri-to-path
                  :notification-handlers (ht ("workspace/projectInitializationComplete"
                                              'lsp-roslyn--on-project-initialization-complete))))

(provide 'lsp-csharp)
;;; lsp-csharp.el ends here
