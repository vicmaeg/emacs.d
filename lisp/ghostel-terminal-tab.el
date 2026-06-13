;;; ghostel-terminal-tab.el --- Perspective layout for ghostel terminal buffers -*- lexical-binding: t; -*-

(require 'cl-lib)

(defun ghostel-terminal-tab--get-buffers ()
  "Return a list of live ghostel buffers."
  (cl-remove-if-not
   (lambda (b)
     (with-current-buffer b
       (derived-mode-p 'ghostel-mode)))
   (buffer-list)))

(defun ghostel-terminal-tab--get-terminal-buffers ()
  "Return a list of live ghostel buffers, excluding AI agent buffers."
  (cl-remove-if-not
   (lambda (b)
     (not (string-match-p "\\`\\*AI Agent" (buffer-name b))))
   (ghostel-terminal-tab--get-buffers)))

(defun ghostel-terminal-tab--layout (buffers)
  "Arrange BUFFERS side-by-side in the current perspective."
  (delete-other-windows)
  (switch-to-buffer (car buffers))
  (dolist (buf (cdr buffers))
    (set-window-buffer (split-window-horizontally) buf))
  (balance-windows))

;;;###autoload
(defun ghostel-terminal-tab ()
  "Create or switch to a perspective showing all ghostel buffers side-by-side.
If no ghostel buffers exist, display a message.  If the \"Terminals\"
perspective already exists, switch to it and refresh the layout."
  (interactive)
  (require 'ghostel)
  (let ((bufs (ghostel-terminal-tab--get-terminal-buffers)))
    (if (null bufs)
        (message "No ghostel buffers")
      (persp-switch "Terminals")
      (dolist (buf bufs)
        (persp-add-buffer buf))
      (ghostel-terminal-tab--layout bufs))))

(provide 'ghostel-terminal-tab)
;;; ghostel-terminal-tab.el ends here
