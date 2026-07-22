;; -*- lexical-binding: t; -*-
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;;; Set up the package manager

(require 'package)

;; In daemon mode, disable package archives to prevent any network access.
;; In normal mode, include MELPA so packages can be installed/updated.
;; Packages must already be installed before starting the daemon.
(if (daemonp)
    (setq package-archives nil)
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/")))

(package-initialize)

;; Do not auto-install packages when Emacs starts as a daemon.
;; To install or update packages, run Emacs directly (not as daemon).
(setq use-package-always-ensure (not (daemonp)))

(add-to-list 'display-buffer-alist
             '("\\`\\*\\(Warnings\\|Compile-Log\\)\\*\\'"
               (display-buffer-no-window)
               (allow-no-window . t)))

;; use ripgrep

(setq xref-search-program 'ripgrep)
(setq grep-command "rg -nS --no-heading "
      grep-use-null-device nil)

;;; Performance tweaks

;; Defer syntax highlighting until you stop typing — reduces micro-stutters
;; in large buffers and tree-sitter modes
(setq redisplay-skip-fontification-on-input t)

;; Increase process output buffer to 4MB — modern LSP servers (rust-analyzer,
;; clangd) send large responses and this avoids many small reads
(setq read-process-output-max (* 4 1024 1024))

(setq ring-bell-function 'ignore)

;; Don't render cursors or highlight selections in non-focused windows
(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

;;; Basic behaviour

(use-package delsel
  :ensure nil
  :hook (after-init . delete-selection-mode))

(defun prot/keyboard-quit-dwim ()
  "Do-What-I-Mean behaviour for a general `keyboard-quit'.

The generic `keyboard-quit' does not do the expected thing when
the minibuffer is open.  Whereas we want it to close the
minibuffer, even without explicitly focusing it.

The DWIM behaviour of this command is as follows:

- When the region is active, disable it.
- When a minibuffer is open, but not focused, close the minibuffer.
- When the Completions buffer is selected, close it.
- In every other case use the regular `keyboard-quit'."
  (interactive)
  (cond
   ((region-active-p)
    (keyboard-quit))
   ((derived-mode-p 'completion-list-mode)
    (delete-completion-window))
   ((> (minibuffer-depth) 0)
    (abort-recursive-edit))
   (t
    (keyboard-quit))))

(define-key global-map (kbd "C-g") #'prot/keyboard-quit-dwim)

(autoload 'zap-up-to-char "misc"
  "Kill up to, but not including ARGth occurrence of CHAR." t)
(global-set-key (kbd "M-/") #'hippie-expand)
(global-set-key (kbd "M-z") #'zap-up-to-char)

;;; Configure backups and autosave folders

(setq backup-directory-alist
      `(("." . ,(locate-user-emacs-file "backups/"))))
(setq auto-save-file-name-transforms
      `((".*" ,(locate-user-emacs-file "auto-save/") t)))

;;; Better defaults

(show-paren-mode 1)

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

(setq-default indent-tabs-mode nil)

(setq apropos-do-all t
      mouse-yank-at-point t
      require-final-newline t
      visible-bell nil
      load-prefer-newer t
      backup-by-copying t
      frame-inhibit-implied-resize t
      completion-ignore-case t
      read-file-name-completion-ignore-case t
      read-buffer-completion-ignore-case t
      ediff-window-setup-function 'ediff-setup-windows-plain)

;;; Line numbers

(setq-default display-line-numbers-type t)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(add-hook 'prog-mode-hook #'electric-pair-local-mode)
(global-hl-line-mode 1)

;;; Tweak the looks of Emacs

(use-package modus-themes
  :ensure t)

(use-package ef-themes
  :ensure t)

(use-package kanagawa-themes
  :ensure t)

(load-theme 'modus-vivendi :no-confirm-loading)

(use-package fontaine
  :ensure t
  :config
  (setq fontaine-latest-state-file
        (locate-user-emacs-file "fontaine-latest-state.eld"))
  (setq fontaine-presets
        '((small
           :default-height 80)
          (regular)
          (medium
           :default-family "Aporetic Serif Mono"
           :default-height 115
           :fixed-pitch-family "Aporetic Serif Mono"
           :variable-pitch-family "Aporetic Sans")
          (large
           :default-height 150)
          (presentation
           :default-height 180)
          (jumbo
           :inherit medium
           :default-height 260)
          (t
           :default-family "Aporetic Serif Mono"
           :default-weight regular
           :default-slant normal
           :default-width normal
           :default-height 100

           :fixed-pitch-family "Aporetic Serif Mono"
           :fixed-pitch-weight nil
           :fixed-pitch-slant nil
           :fixed-pitch-width nil
           :fixed-pitch-height 1.0

           :fixed-pitch-serif-family nil
           :fixed-pitch-serif-weight nil
           :fixed-pitch-serif-slant nil
           :fixed-pitch-serif-width nil
           :fixed-pitch-serif-height 1.0

           :variable-pitch-family "Aporetic Sans"
           :variable-pitch-weight nil
           :variable-pitch-slant nil
           :variable-pitch-width nil
           :variable-pitch-height 1.0

           :mode-line-active-family nil
           :mode-line-active-weight nil
           :mode-line-active-slant nil
           :mode-line-active-width nil
           :mode-line-active-height 1.0

           :mode-line-inactive-family nil
           :mode-line-inactive-weight nil
           :mode-line-inactive-slant nil
           :mode-line-inactive-width nil
           :mode-line-inactive-height 1.0

           :header-line-family nil
           :header-line-weight nil
           :header-line-slant nil
           :header-line-width nil
           :header-line-height 1.0

           :line-number-family nil
           :line-number-weight nil
           :line-number-slant nil
           :line-number-width nil
           :line-number-height 1.0

           :tab-bar-family nil
           :tab-bar-weight nil
           :tab-bar-slant nil
           :tab-bar-width nil
           :tab-bar-height 1.0

           :tab-line-family nil
           :tab-line-weight nil
           :tab-line-slant nil
           :tab-line-width nil
           :tab-line-height 1.0

           :bold-family nil
           :bold-slant nil
           :bold-weight bold
           :bold-width nil
           :bold-height 1.0

           :italic-family nil
           :italic-weight nil
           :italic-slant italic
           :italic-width nil
           :italic-height 1.0

	   :line-spacing nil)))
  :bind
  (("C-c f" . fontaine-set-preset)
   ("C-c F" . fontaine-toggle-preset)))

(fontaine-mode 1)
(fontaine-set-preset (or (fontaine-restore-latest-preset) 'regular))

;; Remember to do M-x and run `nerd-icons-install-fonts' to get the
;; font files.  Then restart Emacs to see the effect.
(use-package nerd-icons
  :ensure t)

(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :config
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package nerd-icons-dired
  :ensure t
  :hook
  (dired-mode . nerd-icons-dired-mode))

;;; Configure the minibuffer and completions

(use-package vertico
  :ensure t
  :hook (after-init . vertico-mode)
  :config
  (setq vertico-cycle t)
  (setq vertico-resize t))

(use-package marginalia
  :ensure t
  :hook (after-init . marginalia-mode)
  :config
  (setq marginalia-align-max-width 80)
  (setq marginalia-align-separator 15))

(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic))
  ;; Clear category defaults so Orderless can filter candidates
  ;; in-buffer (Corfu uses completion-at-point-functions).
  (setq completion-category-defaults nil)
  (setq completion-category-overrides
        '((file (styles partial-completion))
          (buffer (styles orderless basic))
          (info-menu (styles orderless basic)))))

(use-package savehist
  :ensure nil
  :hook (after-init . savehist-mode)
  :config
  (setq savehist-save-minibuffer-history t)
  (add-to-list 'savehist-additional-variables 'vertico-repeat-history)
  (add-to-list 'savehist-additional-variables 'corfu-history)
  ;; Persist kill ring across sessions so clipboard history survives restarts
  (add-to-list 'savehist-additional-variables 'kill-ring)
  ;; Strip text properties from kill-ring entries before saving to keep
  ;; the savehist file from bloating with font/overlay data
  (add-hook 'savehist-save-hook
            (lambda ()
              (setq kill-ring
                    (mapcar #'substring-no-properties
                            (cl-remove-if-not #'stringp kill-ring))))))

(use-package consult
  :ensure t
  :hook (completion-list-mode . consult-preview-mode)
  :bind
  (("C-x b" . consult-buffer)
   ("C-x 4 b" . consult-buffer-other-window)
   ("C-x 5 b" . consult-buffer-other-frame)
   ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
   ("M-y" . consult-yank-pop)
   ("M-s M-s" . consult-ripgrep)
   ("M-s l" . consult-line)
   ("M-s o" . consult-outline)
   ("M-s f" . consult-find)
   ("M-s i" . consult-imenu)
   ("C-x M-:" . consult-complex-command))
  :config
  (setq consult-narrow-key "<")
  (setq consult-line-numbers-width 4)
  (setq consult-async-min-input 2)
  (setq consult-async-refresh-delay 0.15)
  (setq consult-async-input-throttle 0.2)
  (setq consult-async-input-debounce 0.1))

(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim)
   ("C-h B" . embark-bindings)
   ("C-x K" . embark-kill-buffer-and-window))
  :config
  (setq embark-prompter 'embark-keymap-prompter)
  (setq embark-quit-after-action t))

(use-package embark-consult
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-minor-mode))

(use-package corfu
  :ensure t
  :hook ((after-init . global-corfu-mode)
         (after-init . corfu-history-mode)
         (after-init . corfu-popupinfo-mode))
  :config
  ;; TAB indents first, completes if indentation is unchanged
  (setq tab-always-indent 'complete)
  (setq corfu-quit-at-boundary t)
  (setq corfu-quit-no-match t)
  ;; Emacs 30: disable Ispell word completion in text modes (per Corfu README)
  (setq text-mode-ispell-word-completion nil))

(use-package nerd-icons-corfu
  :ensure t
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package cape
  :ensure t
  :init
  ;; Global fallbacks (depth 20); buffer-local major-mode/LSP capfs run first.
  (add-hook 'completion-at-point-functions #'cape-file 20)
  ;; Require a 3-char prefix for dabbrev (replaces removed `cape-dabbrev-min-length').
  (add-hook 'completion-at-point-functions (cape-capf-prefix-length #'cape-dabbrev 3) 20)
  :config
  (defun my/cape-emacs-lisp-setup ()
    (add-hook 'completion-at-point-functions #'cape-elisp-symbol 90 t))
  (add-hook 'emacs-lisp-mode-hook #'my/cape-emacs-lisp-setup)
  (add-hook 'lisp-interaction-mode-hook #'my/cape-emacs-lisp-setup)
  (defun my/cape-prog-setup ()
    (add-hook 'completion-at-point-functions #'cape-keyword 90 t))
  (add-hook 'prog-mode-hook #'my/cape-prog-setup))

(use-package yasnippet
  :ensure t
  :hook (prog-mode . yas-minor-mode)
  :config
  (yas-reload-all)
  (define-key yas-minor-mode-map (kbd "TAB") nil)
  (define-key yas-minor-mode-map [tab] nil)
  (define-key yas-minor-mode-map (kbd "C-c s") #'yas-expand))

(use-package yasnippet-snippets
  :ensure t
  :after yasnippet
  :config (yas-reload-all))

;;; Kill ring and clipboard improvements

;; Save clipboard content into the kill ring before overwriting it, so
;; C-y/M-y can recover text copied from external programs
(setq save-interprogram-paste-before-kill t)

;; Don't save duplicate entries in the kill ring — killing the same text
;; multiple times won't waste kill-ring slots
(setq kill-do-not-save-duplicates t)

;;; The file manager (Dired)

(use-package dired
  :ensure nil
  :commands (dired)
  :hook
  ((dired-mode . dired-hide-details-mode)
   (dired-mode . hl-line-mode))
  :config
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq dired-listing-switches "-alh")
  (setq delete-by-moving-to-trash t)
  (setq dired-dwim-target t)
  (setq dired-kill-when-opening-new-dired-buffer t))

(use-package dired-subtree
  :ensure t
  :after dired
  :bind
  ( :map dired-mode-map
    ("<tab>" . dired-subtree-toggle)
    ("TAB" . dired-subtree-toggle)
    ("<backtab>" . dired-subtree-remove)
    ("S-TAB" . dired-subtree-remove))
  :config
  (setq dired-subtree-use-backgrounds nil))

(use-package trashed
  :ensure t
  :commands (trashed)
  :config
  (setq trashed-action-confirmer 'y-or-n-p)
  (setq trashed-use-header-line t)
  (setq trashed-sort-key '("Date deleted" . t))
  (setq trashed-date-format "%Y-%m-%d %H:%M:%S"))

;;; denote configuration

(use-package denote
  :ensure t
  :hook (dired-mode . denote-dired-mode)
  :bind
  (("C-c n n" . denote)
   ("C-c n r" . denote-rename-file)
   ("C-c n R" . denote-rename-file-using-front-matter)
   ("C-c n l" . denote-link)
   ("C-c n L" . denote-add-links)
   ("C-c n b" . denote-backlinks)
   ("C-c n d" . denote-dired)
   ("C-c n g" . denote-grep)
   ("C-c n j" . denote-journal-new-or-existing-entry)
   ("C-c n J" . denote-journal-new-entry)
   ("C-c n f" . consult-denote-find)
   ("C-c n s" . consult-denote-grep))
  :config
  (setq denote-directory (expand-file-name "~/org/"))
  (setq denote-file-type 'org)
  (setq denote-save-buffers nil)
  (setq denote-known-keywords '("journal" "note" "task" "project"))
  (setq denote-infer-keywords t)
  (setq denote-sort-keywords t)
  (setq denote-prompts '(title keywords))
  (setq denote-date-prompt-use-org-read-date t)
  (denote-rename-buffer-mode 1))

(use-package denote-journal
  :ensure t
  :after denote
  :config
  (setq denote-journal-directory (expand-file-name "journal" denote-directory))
  (setq denote-journal-keyword "journal")
  (setq denote-journal-title-format 'day-date-month-year)
  (setq denote-journal-interval 'daily)
  (defun my-denote-journal-insert-template ()
    (goto-char (point-max))
    (insert "\n* Daily plan\n\n\n* Daily wins\n\n\n* Lessons learned and thoughts\n"))
  (add-hook 'denote-journal-hook #'my-denote-journal-insert-template))

(use-package denote-markdown
  :ensure t
  :after denote
  :config
  (setq denote-markdown-use-markdown-fontification t))

(use-package consult-denote
  :ensure t
  :after (denote consult)
  :config
  (consult-denote-mode 1))

;;; Editing improvements

;; Automatically chmod +x files that start with a shebang line on save
(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)

;; Remove trailing whitespace on save in prog-mode buffers.
;; Uses `write-file-functions' (runs on explicit save, not auto-save)
;; with a buffer-local hook so it never touches non-prog buffers.
(add-hook 'prog-mode-hook
          (lambda ()
            (add-hook 'write-file-functions #'delete-trailing-whitespace nil t)))

;; Use string syntax in re-builder instead of painful double-escaped read syntax
(setq reb-re-syntax 'string)

;; Prevent ffap from pinging hostnames — avoids multi-second hangs on slow
;; or firewalled networks when find-file-at-point sees something.com-like text
(setq ffap-machine-p-known 'reject)

;;; org mode configuration

(setq org-directory (expand-file-name "~/org/"))
(setq org-default-notes-file (expand-file-name "inbox.org" org-directory))
(setq org-agenda-files (list (expand-file-name "todo.org" org-directory)
                             (expand-file-name "inbox.org" org-directory)
                             (expand-file-name "areas" org-directory)
                             (expand-file-name "projects" org-directory)))
(setq org-refile-targets '((nil . (:maxlevel . 9))
                           (org-agenda-files . (:maxlevel . 9))))
(global-set-key (kbd "C-c a") 'org-agenda)

;;; Recent files

(use-package recentf
  :ensure nil
  :hook (after-init . recentf-mode)
  :config
  (setq recentf-max-saved-items 200))

;;; Version control indicators in buffer

(use-package diff-hl
  :ensure t
  :hook ((after-init . global-diff-hl-mode)
         (dired-mode . diff-hl-dired-mode))
  :config
  (setq diff-hl-side 'left)
  ;; Use margin characters in terminal, fringe bitmaps in GUI
  (unless (display-graphic-p)
    (diff-hl-margin-mode 1)))

;;; Jump to visible text

(use-package avy
  :ensure t
  :config
  (setq avy-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l ?q ?w ?e ?r ?t ?y ?u ?i ?o ?p ?z ?x ?c ?v ?b ?n ?m))
  (setq avy-style 'pre)
  (setq avy-all-windows nil)
  (setq avy-single-candidate-action nil)
  :bind
  (("M-g c" . avy-goto-char-timer)
   ("M-g f" . avy-goto-line)
   ("M-g w" . avy-goto-word-1)))

;;; Selection expansion

(use-package expand-region
  :ensure t
  :bind
  (("C-=" . er/expand-region)
   ("C--" . er/contract-region)))

;;; Multiple cursors

(use-package multiple-cursors
  :ensure t
  :bind
  (;; GUI bindings (rexim/official style) — do not work in terminals
   ("C-S-c C-S-c" . mc/edit-lines)
   ("C->"         . mc/mark-next-like-this)
   ("C-<"         . mc/mark-previous-like-this)
   ("C-c C-<"     . mc/mark-all-like-this)
   ("C-<tab>"     . mc/skip-to-next-like-this)
   ("C-|"         . mc/skip-to-previous-like-this)
   ("C-&"         . mc/unmark-next-like-this)
   ("C-%"         . mc/unmark-previous-like-this)
   ;; Terminal-safe fallback (C->, C-<, C-", C-: are unreachable in -t)
   ("C-c m l"     . mc/edit-lines)
   ("C-c m n"     . mc/mark-next-like-this)
   ("C-c m p"     . mc/mark-previous-like-this)
   ("C-c m a"     . mc/mark-all-like-this)
   ("C-c m N"     . mc/unmark-next-like-this)
   ("C-c m P"     . mc/unmark-previous-like-this)
   ("C-c m s"     . mc/skip-to-next-like-this)
   ("C-c m S"     . mc/skip-to-previous-like-this))
  :config
  (setq mc/always-run-for-all t))

;;; Move text

(use-package move-text
  :ensure t
  :bind (("M-p" . move-text-up)
         ("M-n" . move-text-down)))

;;; Window improvements

;; Resize all windows proportionally when splitting — produces balanced
;; layouts instead of one tiny window among large ones
(setq window-combination-resize t)

;; Make C-x 1 toggleable: press once to go single-window, press again
;; to restore the previous layout
(winner-mode +1)

(defun toggle-delete-other-windows ()
  "Delete other windows in frame if any, or restore previous window config."
  (interactive)
  (if (and winner-mode
           (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))

(global-set-key (kbd "C-x 1") #'toggle-delete-other-windows)

;;; project configuration

(setq project-vc-extra-root-markers '("fourthline.yaml" ".project.el"))

;;; Perspective - workspace-centric perspectives

(use-package perspective
  :ensure t
  :bind
  (("C-x C-b" . persp-list-buffers)
   ("C-x k" . persp-kill-buffer*))
  :custom
  (persp-mode-prefix-key (kbd "C-c p"))
  (persp-state-default-file (locate-user-emacs-file "persp-state.el"))
  (persp-sort 'created)
  (persp-show-modestring t)
  (persp-switch-wrap t)
  :init
  (persp-mode)
  :config
  ;; Auto-save perspective state on exit (manual restore only)
  (add-hook 'kill-emacs-hook #'persp-state-save)

  ;; Make previous-buffer/next-buffer perspective-aware
  (setq switch-to-prev-buffer-skip
        (lambda (win buff bury-or-kill)
          (not (persp-is-current-buffer buff))))

  ;; Add perspective buffer source to consult-buffer
  (with-eval-after-load 'consult
    (defvar consult--source-perspective
      (list :name     "Perspective Buffers"
            :narrow   ?p
            :history  'buffer-name-history
            :category 'buffer
            :state    #'consult--buffer-state
            :default  t
            :items    (lambda () (consult--buffer-query
                             :predicate #'persp-is-current-buffer
                             :sort 'visibility
                             :as #'buffer-name)))
      "Set perspective buffer list for consult-buffer.")
    (add-to-list 'consult-buffer-sources 'consult--source-perspective)))

;;; version control

(use-package magit
  :ensure t
  :commands (magit-status))

(use-package git-link
  :ensure t
  :bind
  (("C-c g l" . git-link)
   ("C-c g c" . git-link-commit)
   ("C-c g h" . git-link-homepage)))

;;; Language Servers

(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (setq lsp-log-io nil)
  (setq lsp-idle-delay 0.5)
  ;; We use Corfu, don't let lsp-mode configure company
  (setq lsp-completion-provider :none)
  (setq lsp-enable-symbol-highlighting nil)
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-enable-code-lens nil)
  (setq lsp-enable-snippet t)
  (setq lsp-signature-auto-activate nil)
  (setq lsp-modeline-code-actions-enable nil)
  (setq lsp-modeline-diagnostics-enable nil)
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-diagnostics-provider :flymake)
  (setq lsp-keep-workspace-alive nil)
  (setq lsp-enable-file-watchers nil)
  (setq lsp-response-timeout 10)
  (setq lsp-use-plists t)
  (setq lsp-restart 'auto-restart)
  (setq lsp-clients-clangd-args
        '("--clang-tidy"
          "--header-insertion=never"
          "--completion-style=detailed"))
  ;; Filter LSP candidates with Orderless (per Corfu wiki)
  (defun my/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(orderless)))
  (add-hook 'lsp-completion-mode-hook #'my/lsp-mode-setup-completion)
  (lsp-enable-which-key-integration))

(add-to-list 'load-path (locate-user-emacs-file "lisp"))
(require 'lsp-csharp)
(require 'lsp-c)
(require 'my-perspectives)
(global-set-key (kbd "C-c o") my/persp-map)

(use-package which-key
  :ensure nil
  :demand t
  :config
  (which-key-mode))

;;; Tree-sitter configuration

(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)  ; Ask before installing grammars
  :config
  ;; Add C# recipe for treesit-auto
  (add-to-list 'treesit-auto-recipe-list
               (make-treesit-auto-recipe
                :lang 'c-sharp
                :ts-mode 'csharp-ts-mode
                :remap 'csharp-mode
                :url "https://github.com/tree-sitter/tree-sitter-c-sharp"
                :source-dir "src"))
  ;; Register tree-sitter modes for all supported languages
  (treesit-auto-add-to-auto-mode-alist 'all)
  ;; Enable global mode
  (global-treesit-auto-mode))

;;; Dotnet CLI integration

(use-package sharper
  :ensure t
  :bind ("C-c d" . sharper-main-transient))

;;; Miscellaneous improvements

;; Auto-revert buffers when files change on disk — essential when AI agents
;; or external tools modify files behind the scenes.
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)
(setq auto-revert-check-vc-info t)

;; After the first C-u C-SPC, keep pressing just C-SPC to pop more marks
;; — makes mark-ring navigation much faster
(setq set-mark-command-repeat-pop t)

;; Auto-select help windows so the cursor jumps there immediately after
;; C-h f, C-h v, etc. — no more C-x o every time
(setq help-window-select t)

;; Remember cursor position in files and recenter after restoring it,
;; so you're not stuck at the bottom of the window when reopening a file
(save-place-mode 1)
(advice-add 'save-place-find-file-hook :after
            (lambda (&rest _)
              (when buffer-file-name (ignore-errors (recenter)))))

;;; Terminal emulator

(use-package ghostel
  :ensure t
  :commands (ghostel)
  :bind
  (("C-c t" . ghostel)
   ("C-x p t" . ghostel-project))
  :config
  (setq ghostel-shell (or (getenv "SHELL") "/bin/bash"))
  (setq ghostel-kill-buffer-on-exit t)
  (setq ghostel-max-scrollback 10000)
  (setq ghostel-enable-url-detection t)
  (setq ghostel-enable-file-detection t)
  (setq ghostel-adaptive-fps t)
  (setq ghostel-enable-osc52 t))

(require 'ghostel-compile)
(global-set-key (kbd "C-c c") #'ghostel-compile)

(require 'ghostel-eshell)
(require 'em-term)
(add-hook 'eshell-load-hook #'ghostel-eshell-visual-command-mode)
(add-to-list 'eshell-visual-commands "opencode")
(add-to-list 'eshell-visual-commands "cursor")

(require 'my-persp-terminals)
(require 'my-persp-agents)
(require 'ghostel-agent-project)

(defun my/project-magit-status ()
  "Run `magit-status' in the root of the current project."
  (interactive)
  (let ((default-directory (project-root (project-current t))))
    (magit-status)))

(with-eval-after-load 'project
  (define-key project-prefix-map (kbd "a") #'ghostel-agent-project-cursor)
  (define-key project-prefix-map (kbd "A") #'ghostel-agent-project-opencode)
  (let ((found-magit nil))
    (dolist (entry project-switch-commands)
      (when (and (listp entry) (eq (car entry) #'magit-status))
        (setq found-magit t)))
    (unless found-magit
      (add-to-list 'project-switch-commands '(my/project-magit-status "Magit" ?m))))
  (add-to-list 'project-switch-commands '(ghostel-project "Terminal" ?t))
  (add-to-list 'project-switch-commands '(ghostel-agent-project-cursor "Agent (Cursor)" ?a))
  (add-to-list 'project-switch-commands '(ghostel-agent-project-opencode "Agent (OpenCode)" ?A)))

;;; markdown mode
(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "pandoc")
  :bind (:map markdown-mode-map
         ("C-c C-e" . markdown-do)))
