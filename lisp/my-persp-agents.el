;;; my-persp-agents.el --- Perspective layout for AI agent ghostel buffers -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'perspective)
(require 'my-persp-terminals)

(declare-function persp-switch "perspective")
(declare-function persp-add-buffer "perspective")

(defvar my/persp-map)

;;; Buffer detection

(defun my/persp-agents--detect (buffer)
  "Return the agent type for BUFFER, or nil if no agent is active.
Detects `opencode' and `cursor' from buffer names starting with
`*AI Agent opencode' or `*AI Agent cursor', or from legacy patterns
(`OpenCode', `OC |', `Cursor Agent')."
  (let ((case-fold-search t)
        (name (buffer-name buffer)))
    (cond
     ((string-match-p (rx bol "*AI Agent opencode") name) 'opencode)
     ((string-match-p (rx bol "*AI Agent cursor") name)   'cursor)
     ((string-match-p (rx (or "OpenCode" "OC |")) name)   'opencode)
     ((string-match-p "Cursor Agent" name)                'cursor)
     (t nil))))

(defun my/persp-agents--buffers ()
  "Return a list of live ghostel buffers that are AI agents."
  (cl-remove-if-not
   (lambda (b) (my/persp-agents--detect b))
   (my/persp-terminals--get-buffers)))

;;; Perspective command

;;;###autoload
(defun my/persp-agents ()
  "Create or switch to a perspective showing AI agent ghostel buffers side-by-side.
If no agent buffers exist, display a message.  If the \"AI Agents\"
perspective already exists, switch to it and refresh the layout."
  (interactive)
  (let ((bufs (my/persp-agents--buffers)))
    (if (null bufs)
        (message "No AI agent buffers")
      (persp-switch "AI Agents")
      (dolist (buf bufs)
        (persp-add-buffer buf))
      (my/persp-terminals--layout bufs))))

(with-eval-after-load 'my-perspectives
  (define-key my/persp-map (kbd "a") #'my/persp-agents))

(provide 'my-persp-agents)
;;; my-persp-agents.el ends here
