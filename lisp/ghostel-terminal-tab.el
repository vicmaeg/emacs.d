;;; ghostel-terminal-tab.el --- Tab layout for ghostel terminal buffers -*- lexical-binding: t; -*-

(require 'cl-lib)

(defun ghostel-terminal-tab--get-buffers ()
  "Return a list of live ghostel buffers."
  (cl-remove-if-not
   (lambda (b)
     (with-current-buffer b
       (derived-mode-p 'ghostel-mode)))
   (buffer-list)))

(defun ghostel-terminal-tab--layout (buffers)
  "Arrange BUFFERS side-by-side in the current tab."
  (delete-other-windows)
  (switch-to-buffer (car buffers))
  (dolist (buf (cdr buffers))
    (set-window-buffer (split-window-horizontally) buf))
  (balance-windows))

(defun ghostel-terminal-tab--tab-named-p (name)
  "Return non-nil if a tab named NAME exists."
  (cl-member name (tab-bar-tabs) :key #'(lambda (tab) (alist-get 'name tab)) :test #'equal))

;;;###autoload
(defun ghostel-terminal-tab ()
  "Create or switch to a tab showing all ghostel buffers side-by-side.
If no ghostel buffers exist, display a message.  If the \"Terminals\"
tab already exists, switch to it and refresh the layout."
  (interactive)
  (require 'ghostel)
  (let ((bufs (ghostel-terminal-tab--get-buffers)))
    (if (null bufs)
        (message "No ghostel buffers")
      (if (ghostel-terminal-tab--tab-named-p "Terminals")
          (tab-bar-switch-to-tab "Terminals")
        (tab-bar-new-tab)
        (tab-bar-rename-tab "Terminals"))
      (ghostel-terminal-tab--layout bufs))))

(provide 'ghostel-terminal-tab)
;;; ghostel-terminal-tab.el ends here