;; -*- lexical-binding: t; -*-
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

;;; Performance tweaks

;; Defer syntax highlighting until you stop typing — reduces micro-stutters
;; in large buffers and tree-sitter modes
(setq redisplay-skip-fontification-on-input t)

;; Increase process output buffer to 4MB — modern LSP servers (rust-analyzer,
;; clangd) send large responses and this avoids many small reads
(setq read-process-output-max (* 4 1024 1024))

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

;;; Configure backups and autosave folders

(setq backup-directory-alist
      `(("." . ,(locate-user-emacs-file "backups/"))))
(setq auto-save-file-name-transforms
      `((".*" ,(locate-user-emacs-file "auto-save/") t)))



;;; Line numbers

(setq-default display-line-numbers-type t)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(global-hl-line-mode 1)

;;; Tweak the looks of Emacs

(let ((mono-spaced-font "JetBrains Mono")
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
        '((file (styles . (partial-completion orderless)))
          (buffer (styles . (orderless basic)))
          (info-menu (styles . (orderless basic))))))

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

;;; Editing improvements

;; Automatically chmod +x files that start with a shebang line on save
(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)

;; Use string syntax in re-builder instead of painful double-escaped read syntax
(setq reb-re-syntax 'string)

;; Prevent ffap from pinging hostnames — avoids multi-second hangs on slow
;; or firewalled networks when find-file-at-point sees something.com-like text
(setq ffap-machine-p-known 'reject)

;;; org mode configuration

(setq org-agenda-files '("~/org" "~/org/journal"))

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
  (("C-;" . avy-goto-char-timer)
   ("M-g f" . avy-goto-line)
   ("M-g w" . avy-goto-word-1)))

;;; Selection expansion

(use-package expand-region
  :ensure t
  :bind
  (("C-=" . er/expand-region)
   ("C--" . er/contract-region)))

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

;;; Tab bar improvements
;; Only show the tab bar when there is more than one tab.
;; This keeps the UI clean until you actually need tabs.
(setq tab-bar-show 1)

;; Remove the [x] close and [+] new-tab buttons for a cleaner look.
(setq tab-bar-close-button-show nil)
(setq tab-bar-new-button-show nil)

;; Show just the tab names, no extra widgets.
(setq tab-bar-format '(tab-bar-format-tabs tab-bar-separator))

;; Make the tab bar compact and remove the default box borders.
(set-face-attribute 'tab-bar nil :height 0.9 :box nil)
(set-face-attribute 'tab-bar-tab nil :box nil :weight 'bold)
(set-face-attribute 'tab-bar-tab-inactive nil :box nil)

;;; project configuration

(setq project-vc-extra-root-markers '("fourthline.yaml" ".project.el"))

;;; version control

(use-package magit
  :ensure t)

;;; Language Servers (see lisp/lsp-csharp.el)

(add-to-list 'load-path (locate-user-emacs-file "lisp"))
(require 'lsp-csharp)

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

;;; agent-shell

(use-package agent-shell
  :ensure t
  :config
  (setq agent-shell-opencode-authentication
        (agent-shell-opencode-make-authentication :none t))
  (setq agent-shell-opencode-default-model-id "opencode-go/glm-5.1")
  (setq agent-shell-cursor-acp-command '("agent" "acp"))
  (setq agent-shell-preferred-agent-config
        (agent-shell-opencode-make-agent-config)))

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

(require 'ghostel-terminal-tab)
(require 'ghostel-agent-tab)
(global-set-key (kbd "C-c T") #'ghostel-terminal-tab)
(global-set-key (kbd "C-c a") #'ghostel-agent-tab)

;;; markdown mode
(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "pandoc")
  :bind (:map markdown-mode-map
         ("C-c C-e" . markdown-do)))
