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

(add-hook 'csharp-ts-mode-hook #'lsp-deferred)
(add-hook 'csharp-ts-mode-hook #'flymake-mode)
(add-hook 'csharp-ts-mode-hook #'electric-pair-local-mode)

(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (setq lsp-log-io nil)
  (setq lsp-idle-delay 0.5)
  (setq lsp-completion-provider :capf)
  (setq lsp-enable-symbol-highlighting nil)
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-enable-code-lens nil)
  (setq lsp-enable-snippet t)
  (setq lsp-signature-auto-activate nil)
  (setq lsp-modeline-code-actions-enable nil)
  (setq lsp-modeline-diagnostics-enable nil)
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-diagnostics-provider :flymake)
  (setq lsp-roslyn-server-log-level "Warning")
  (setq lsp-keep-workspace-alive nil)
  (setq lsp-enable-file-watchers nil)
  (setq lsp-response-timeout 10)
  (setq lsp-use-plists t)
  (setq gc-cons-threshold 100000000)
  (setq lsp-restart 'auto-restart)
  (lsp-enable-which-key-integration))

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

(provide 'lsp-csharp)
;;; lsp-csharp.el ends here
