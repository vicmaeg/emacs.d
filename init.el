(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;;; Set up the package manager

(require 'package)
(package-initialize)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

(when (< emacs-major-version 29)
  (unless (package-installed-p 'use-package)
    (unless package-archive-contents
      (package-refresh-contents))
    (package-install 'use-package)))

(add-to-list 'display-buffer-alist
             '("\\`\\*\\(Warnings\\|Compile-Log\\)\\*\\'"
               (display-buffer-no-window)
               (allow-no-window . t)))

;; use ripgrep

(setq xref-search-program 'ripgrep)
(setq grep-command "rg -nS --no-heading "
      grep-use-null-device nil)

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

;;; Configure backups and autosave folders

(setq backup-directory-alist
      `(("." . ,(locate-user-emacs-file "backups/"))))
(setq auto-save-file-name-transforms
      `((".*" ,(locate-user-emacs-file "auto-save/") t)))



;;; Tweak the looks of Emacs

(let ((mono-spaced-font "Monospace")
      (proportionately-spaced-font "Sans"))
  (set-face-attribute 'default nil :family mono-spaced-font :height 100)
  (set-face-attribute 'fixed-pitch nil :family mono-spaced-font :height 1.0)
  (set-face-attribute 'variable-pitch nil :family proportionately-spaced-font :height 1.0))

(use-package modus-themes
  :ensure t)

(use-package gruber-darker-theme
  :ensure t
  :config
  (load-theme 'gruber-darker :no-confirm-loading))

;; Remember to do M-x and run `nerd-icons-install-fonts' to get the
;; font files.  Then restart Emacs to see the effect.
(use-package nerd-icons
  :ensure t)

(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :config
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package nerd-icons-corfu
  :ensure t
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

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
  ;; Eglot sets `flex` for its own categories; override so Orderless can
  ;; filter LSP candidates in-buffer (see Corfu wiki: Eglot + Orderless).
  (setq completion-category-defaults nil)
  (setq completion-category-overrides
        '((eglot (styles orderless))
          (eglot-capf (styles orderless))
          (file (styles . (partial-completion orderless)))
          (buffer (styles . (orderless basic)))
          (info-menu (styles . (orderless basic))))))

(use-package savehist
  :ensure nil
  :hook (after-init . savehist-mode)
  :config
  (setq savehist-save-minibuffer-history t)
  (add-to-list 'savehist-additional-variables 'vertico-repeat-history)
  (add-to-list 'savehist-additional-variables 'corfu-history))

(use-package consult
  :ensure t
  :hook (completion-list-mode . consult-preview-mode)
  :bind
  (("C-x b" . consult-buffer)
   ("C-x 4 b" . consult-buffer-other-window)
   ("C-x 5 b" . consult-buffer-other-frame)
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
  :hook (after-init . global-corfu-mode)
  :bind
  (:map corfu-map
        ("<tab>" . corfu-complete)
        ("M-m" . corfu-move-to-minibuffer)
        ("M-q" . corfu-info-documentation))
  :config
  (setq tab-always-indent 'complete)
  (setq corfu-preview-current nil)
  (setq corfu-min-width 20)
  (setq corfu-max-width 80)
  (setq corfu-popupinfo-delay '(1.25 . 0.5))
  (corfu-popupinfo-mode 1)

  ;; Pop up completions while typing (Eglot + Corfu expect fresh sessions).
  (setq corfu-auto t)
  (setq corfu-auto-delay 0.2)

  ;; Sort by input history (no need to modify `corfu-sort-function').
  (with-eval-after-load 'savehist
    (corfu-history-mode 1)
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(defun corfu-move-to-minibuffer ()
  "Move current completion to minibuffer."
  (interactive)
  (when (completion-in-region--data)
    (let ((completion (thing-at-point 'symbol)))
      (corfu-quit)
      (minibuffer-with-setup-hook
          (lambda ()
            (insert completion))
        (call-interactively #'embark-act)))))

(advice-add #'eglot-completion-at-point :around #'cape-wrap-buster)

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
    (insert "\n* Do today\n\n\n* Meeting notes\n\n\n* Learnings for the day\n"))
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

;;; org mode configuration

(setq org-agenda-files '("~/org" "~/org/journal"))

;;; project configuration

(setq project-vc-extra-root-markers '("fourthline.yaml"))

;;; version control

(use-package magit
  :ensure t)

;;; Language Servers configurations

(use-package cape
  :ensure t
  :defer t)

;; Built into Emacs 29+; on older versions install `eglot' from GNU ELPA.
(use-package eglot
  :ensure nil
  :defer t
  ;; When non-nil, kill the LSP process after the last managed buffer closes.
  ;; Default nil keeps servers running so reopening a file reconnects quickly.
  :custom (eglot-autoshutdown t)
  :config
  ;; Corfu caches the completion table; Eglot does not refresh it each edit.
  ;; `cape-wrap-buster' re-fetches candidates from the LSP when needed.
  (require 'cape)
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster))

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

;; Ensure eglot works with csharp-ts-mode
(add-hook 'csharp-ts-mode-hook #'eglot-ensure)

;; Enable electric-pair-mode for better brace handling in C#
(add-hook 'csharp-ts-mode-hook #'electric-pair-local-mode)

;;; Dotnet CLI integration

(use-package sharper
  :ensure t
  :bind ("C-c d" . sharper-main-transient))

;;; markdown mode
(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "pandoc")
  :bind (:map markdown-mode-map
         ("C-c C-e" . markdown-do)))

