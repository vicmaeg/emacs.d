;;; my-persp-terminals.el --- Perspective layout for ghostel terminal buffers -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'perspective)

(declare-function persp-switch "perspective")
(declare-function persp-add-buffer "perspective")

(defvar my/persp-map)

(defun my/persp-terminals--get-buffers ()
  "Return a list of live ghostel buffers."
  (cl-remove-if-not
   (lambda (b)
     (with-current-buffer b
       (derived-mode-p 'ghostel-mode)))
   (buffer-list)))

(defun my/persp-terminals--get-terminal-buffers ()
  "Return a list of live ghostel buffers, excluding AI agent buffers."
  (cl-remove-if-not
   (lambda (b)
     (not (string-match-p "\\`\\*AI Agent" (buffer-name b))))
   (my/persp-terminals--get-buffers)))

(defun my/persp-terminals--layout (buffers)
  "Arrange BUFFERS side-by-side in the current perspective."
  (delete-other-windows)
  (switch-to-buffer (car buffers))
  (dolist (buf (cdr buffers))
    (set-window-buffer (split-window-horizontally) buf))
  (balance-windows))

;;;###autoload
(defun my/persp-terminals ()
  "Create or switch to a perspective showing all ghostel buffers side-by-side.
If no ghostel buffers exist, display a message.  If the \"Terminals\"
perspective already exists, switch to it and refresh the layout."
  (interactive)
  (require 'ghostel)
  (let ((bufs (my/persp-terminals--get-terminal-buffers)))
    (if (null bufs)
        (message "No ghostel buffers")
      (persp-switch "Terminals")
      (dolist (buf bufs)
        (persp-add-buffer buf))
      (my/persp-terminals--layout bufs))))

(with-eval-after-load 'my-perspectives
  (define-key my/persp-map (kbd "t") #'my/persp-terminals))

(provide 'my-persp-terminals)
;;; my-persp-terminals.el ends here
