;;; ghostel-tab.el --- Tab layout for all ghostel terminal buffers -*- lexical-binding: t; -*-

(defun ghostel-tab--get-buffers ()
  "Return a list of live ghostel buffers."
  (cl-remove-if-not
   (lambda (b)
     (with-current-buffer b
       (derived-mode-p 'ghostel-mode)))
   (buffer-list)))

(defun ghostel-tab--tab-name (tab)
  "Return the name of TAB."
  (alist-get 'name tab))

(defun ghostel-tab--tab-exists-p ()
  "Return non-nil if a tab named \"Terminals\" exists."
  (cl-member "Terminals" (tab-bar-tabs) :key #'ghostel-tab--tab-name :test #'equal))

(defun ghostel-tab--layout (buffers)
  "Arrange BUFFERS side-by-side in the current tab."
  (delete-other-windows)
  (switch-to-buffer (car buffers))
  (dolist (buf (cdr buffers))
    (set-window-buffer (split-window-horizontally) buf))
  (balance-windows))

;;;###autoload
(defun ghostel-tab ()
  "Create or switch to a tab showing all ghostel buffers side-by-side.
If no ghostel buffers exist, display a message.  If the \"Terminals\"
tab already exists, switch to it and refresh the layout."
  (interactive)
  (require 'ghostel)
  (let ((bufs (ghostel-tab--get-buffers)))
    (if (null bufs)
        (message "No ghostel buffers")
      (if (ghostel-tab--tab-exists-p)
          (tab-bar-switch-to-tab "Terminals")
        (tab-bar-new-tab)
        (tab-bar-rename-tab "Terminals"))
      (ghostel-tab--layout bufs))))

(provide 'ghostel-tab)
;;; ghostel-tab.el ends here
