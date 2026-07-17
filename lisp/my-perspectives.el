;;; my-perspectives.el --- Predefined perspective layouts -*- lexical-binding: t; -*-

(require 'perspective)
(require 'project)

(declare-function perspectives-hash "perspective")
(declare-function org-agenda-list "org-agenda")
(defvar org-agenda-window-setup)

(defun my/persp--switch-or-create (name setup-fn)
  "Switch to perspective NAME; run SETUP-FN only when it is newly created."
  (let ((existing (gethash name (perspectives-hash))))
    (persp-switch name)
    (unless existing
      (funcall setup-fn))))

(defun my/persp--org-setup ()
  "Build the org layout: todo.org left, agenda week + inbox right.
The inbox.org pane is only opened when it contains text."
  (delete-other-windows)
  (let ((left (find-file-noselect "~/org/todo.org")))
    (persp-add-buffer left)
    (set-window-buffer (selected-window) left))
  (let ((right (split-window-horizontally)))
    (with-selected-window right
      (let ((org-agenda-window-setup 'current-window))
        (org-agenda-list nil nil 'week)))
    (when-let ((ab (get-buffer "*Org Agenda*")))
      (persp-add-buffer ab))
    (let ((inbox (find-file-noselect "~/org/inbox.org")))
      (when (> (buffer-size inbox) 0)
        (with-selected-window right
          (let ((bottom (split-window-vertically)))
            (set-window-buffer bottom inbox)
            (persp-add-buffer inbox))))))
  (balance-windows))

;;;###autoload
(defun my/persp-org ()
  "Switch to the \"org\" perspective, creating it on first use."
  (interactive)
  (my/persp--switch-or-create "org" #'my/persp--org-setup))

(defun my/persp--config-setup ()
  "Build the config layout: init.el in a single window."
  (delete-other-windows)
  (let ((buf (find-file-noselect "~/.emacs.d/init.el")))
    (persp-add-buffer buf)
    (set-window-buffer (selected-window) buf)))

;;;###autoload
(defun my/persp-config ()
  "Switch to the \"config\" perspective, creating it on first use."
  (interactive)
  (my/persp--switch-or-create "config" #'my/persp--config-setup))

;;;###autoload
(defun my/persp-project ()
  "Prompt for a project like `C-x p p' and switch to a perspective named after it.
Opens dired at the project root, then runs `project-switch-project' so
the project command dispatch menu (find file, magit, etc.) is shown.
All of this happens only when the perspective is newly created; later
calls just switch to it."
  (interactive)
  (let* ((dir (project-prompt-project-dir))
         (proj (project-current nil dir))
         (name (if proj (project-name proj)
                 (file-name-nondirectory (directory-file-name dir)))))
    (my/persp--switch-or-create
     name
     (lambda ()
       (delete-other-windows)
       (let ((d-buf (dired-noselect dir)))
         (persp-add-buffer d-buf)
         (set-window-buffer (selected-window) d-buf)
         (with-current-buffer d-buf
           (project-switch-project dir)))))))

(defvar my/persp-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "o") #'my/persp-org)
    (define-key map (kbd "c") #'my/persp-config)
    (define-key map (kbd "p") #'my/persp-project)
    map)
  "Keymap for predefined perspective commands.")

(provide 'my-perspectives)
;;; my-perspectives.el ends here
