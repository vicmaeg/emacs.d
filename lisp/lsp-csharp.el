;;; lsp-csharp.el --- C# LSP configuration (eglot + lsp-mode) -*- lexical-binding: t; -*-

;; Pull diagnostics for C# via roslyn LSP.
;;
;; The roslyn language server uses pull diagnostics (LSP 3.17+
;; `textDocument/diagnostic') instead of push diagnostics
;; (`textDocument/publishDiagnostics').  Neither eglot nor lsp-mode
;; support this out of the box — both need patched capabilities and
;; handlers.

;;; Code

(require 'cl-lib)

;;; ─── Client selection ─────────────────────────────────────────────

(defcustom lsp-csharp-client 'lsp-mode
  "LSP client for C# buffers.
`lsp-mode' — feature-rich client with pull-diagnostics override (default).
`eglot'  — built-in client with pull-diagnostics patch (requires
           the GNU-devel ELPA version of eglot)."
  :type '(choice (const eglot) (const lsp-mode))
  :group 'lsp-csharp)

(defun lsp-csharp-setup ()
  "Start the configured LSP client for the current C# buffer."
  (pcase lsp-csharp-client
    ('eglot    (eglot-ensure))
    ('lsp-mode (lsp-deferred))))

(defun lsp-csharp-toggle ()
  "Toggle between eglot and lsp-mode for C# and reconnect."
  (interactive)
  (setq lsp-csharp-client
        (if (eq lsp-csharp-client 'eglot) 'lsp-mode 'eglot))
  (message "C# LSP client → %s" lsp-csharp-client)
  (when (derived-mode-p 'csharp-ts-mode)
    (ignore-errors
      (when-let* ((server (eglot-current-server)))
        (eglot-shutdown server)))
    (ignore-errors (lsp-disconnect))
    (lsp-csharp-setup)))

;;; ─── Eglot (fallback) ──────────────────────────────────────────────

(use-package eglot
  :ensure nil
  :config

  ;; Register roslyn as the server for csharp-ts-mode.
  (add-to-list 'eglot-server-programs
               `((csharp-ts-mode :language-id "csharp")
                 . ("roslyn-language-server" "--stdio")))

  ;; ── Capability patches for roslyn pull diagnostics ──
  ;;
  ;; Roslyn requires three things that eglot doesn't advertise by default:
  ;;
  ;; 1. `textDocument.diagnostic.dynamicRegistration: true`
  ;;    Roslyn only registers pull diagnostics for clients that accept
  ;;    dynamic registration of `textDocument/diagnostic`.
  ;;    Eglot sends `:json-false`.  We flip it to `true`.
  ;;
  ;; 2. `workspace.diagnostics.refreshSupport: true`
  ;;    After background analysis, roslyn sends
  ;;    `workspace/diagnostic/refresh` to tell the client to re-pull.
  ;;    Eglot doesn't advertise this capability.  We add it.

  (defun lsp-csharp--eglot-patch-capabilities (caps)
    "Advertise pull-diagnostic support in CAPS for roslyn."
    (plist-put caps :textDocument
               (plist-put (plist-get caps :textDocument)
                          :diagnostic '(:dynamicRegistration t)))
    (plist-put caps :workspace
               (plist-put (plist-get caps :workspace)
                          :diagnostics '(:refreshSupport t)))
    caps)

  (advice-add 'eglot-client-capabilities :filter-return
              #'lsp-csharp--eglot-patch-capabilities)

  ;; Dynamic registration handler for `textDocument/diagnostic'.
  ;; Roslyn sends client/registerCapability with this method at startup.
  ;; The default eglot method just warns and rejects; we store the
  ;; capability so `eglot-server-capable :diagnosticProvider' returns non-nil
  ;; and the pull-diagnostics code path in `eglot-flymake-backend' fires.
  (cl-defmethod eglot-register-capability
    (server (_method (eql textDocument/diagnostic)) _id &key &allow-other-keys)
    (setf (eglot--capabilities server)
          (plist-put (eglot--capabilities server) :diagnosticProvider t))
    (list t "Accepted pull diagnostics registration"))

  ;; Handle `workspace/diagnostic/refresh' — roslyn sends this request
  ;; after background analysis to tell the client that diagnostics are
  ;; stale and should be re-pulled.  Without this handler eglot would
  ;; respond with an error, and diagnostics never update after the
  ;; initial pull.
  (cl-defmethod eglot-handle-request
    (server (_method (eql workspace/diagnostic/refresh)))
    "Re-pull diagnostics when roslyn says they have changed."
    (dolist (buf (eglot--managed-buffers server))
      (eglot--when-live-buffer buf
        (when eglot--managed-mode
          (eglot--flymake-pull)))))

  (add-hook 'csharp-ts-mode-hook #'lsp-csharp-setup)

  ;; Both eglot and lsp-mode use flymake for diagnostics.
  (use-package flymake
    :ensure nil
    :hook (csharp-ts-mode . flymake-mode))

  (add-hook 'csharp-ts-mode-hook #'electric-pair-local-mode))

;;; ─── lsp-mode (primary) ────────────────────────────────────────────

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
  ;; Auto-restart on unexpected exit instead of prompting.  Combined with
  ;; lsp-keep-workspace-alive=nil, the server shuts down cleanly when the
  ;; last buffer closes — but if it crashes mid-session it restarts silently.
  (setq lsp-restart 'auto-restart)
  (gc-cons-threshold 100000000)
  (lsp-enable-which-key-integration))

(defun lsp-csharp--patch-capabilities (caps)
  "Patch CAPS to enable pull diagnostics for roslyn.
 lsp-mode defaults to `:json-false' for two capability keys that roslyn
requires: `textDocument.diagnostic.dynamicRegistration' and
`workspace.diagnostics.refreshSupport'.  This flips them to `t'.
CAPS is an alist as returned by `lsp--client-capabilities'."
  ;; workspace.diagnostics.refreshSupport → t
  (setcdr (assoc 'diagnostics (cdr (assoc 'workspace caps)))
          '((refreshSupport . t)))
  ;; textDocument.diagnostic.dynamicRegistration → t, relatedDocumentSupport → t
  (setcdr (assoc 'diagnostic (cdr (assoc 'textDocument caps)))
          '((dynamicRegistration . t) (relatedDocumentSupport . t)))
  caps)

(advice-add 'lsp--client-capabilities :filter-return
            #'lsp-csharp--patch-capabilities)

(defun lsp-csharp--roslyn-on-initialized (workspace)
  "Open the solution file and configure full-solution analysis for roslyn."
  (lsp-roslyn-open-solution-file)
  (with-lsp-workspace workspace
    (lsp--set-configuration
     #s(hash-table
        size 30
        test equal
        data (
              "csharp|background_analysis.dotnet_analyzer_diagnostics_scope" "fullSolution"
              "csharp|background_analysis.dotnet_compiler_diagnostics_scope" "fullSolution"
              )))))

(advice-add 'lsp-roslyn--on-initialized :override
            #'lsp-csharp--roslyn-on-initialized)

(provide 'lsp-csharp)
;;; lsp-csharp.el ends here