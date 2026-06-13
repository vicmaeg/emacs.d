;;; ghostel-agent-tab.el --- Perspective layout for AI agent ghostel buffers -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'project)
(require 'ghostel)
(require 'ghostel-terminal-tab)

;;; Customizable agent commands

(defcustom ghostel-agent-opencode-command "opencode"
  "Command string sent to the shell to launch the OpenCode agent."
  :type 'string
  :group 'ghostel)

(defcustom ghostel-agent-cursor-command "agent"
  "Command string sent to the shell to launch the Cursor agent."
  :type 'string
  :group 'ghostel)

;;; Buffer detection

(defun ghostel-agent-tab--detect (buffer)
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

(defun ghostel-agent-tab--buffers ()
  "Return a list of live ghostel buffers that are AI agents."
  (cl-remove-if-not
   (lambda (b) (ghostel-agent-tab--detect b))
   (ghostel-terminal-tab--get-buffers)))

(defun ghostel-agent-tab--label (type)
  "Return a display label for agent TYPE."
  (pcase type
    ('opencode "OpenCode")
    ('cursor "Cursor")
    (_ "Unknown")))

;;; Agent launcher

(defun ghostel-agent-project--run (agent-type command)
  "Launch an AI agent in a ghostel terminal for the current project.

Starts a full shell (with shell integration and PATH), then sends
COMMAND to it.  The buffer is named `*AI Agent AGENT-TYPE: PROJECT*'
and title tracking is disabled so the name never changes.

If the buffer already has a live ghostel process, switch to it
instead of creating a new one."
  (let* ((proj      (project-current t))
         (proj-name (project-name proj))
         (default-directory (project-root proj))
         (buf-name  (format "*AI Agent %s: %s*" agent-type proj-name))
         (existing  (get-buffer buf-name)))
    (if (and existing
             (buffer-local-value 'ghostel--process existing)
             (process-live-p (buffer-local-value 'ghostel--process existing)))
        (pop-to-buffer existing)
      ;; Kill stale buffer with a dead process so `ghostel' creates a
      ;; fresh one instead of reusing it with a frozen terminal.
      (when existing (kill-buffer existing))
      (let ((ghostel-buffer-name buf-name)
            buffer)
        (ghostel)
        (setq buffer (current-buffer))
        (with-current-buffer buffer
          ;; Freeze the buffer name — ghostel title tracking must not
          ;; rename it away from the `*AI Agent ...*' pattern.
          (setq-local ghostel-set-title-function nil)
          ;; Send the agent command.  The PTY buffers input so the
          ;; shell reads it once its prompt is ready.
          (ghostel-send-string (concat command "\n")))
        buffer))))

;;;###autoload
(defun ghostel-agent-project-opencode ()
  "Launch an OpenCode agent in a ghostel terminal for the current project."
  (interactive)
  (ghostel-agent-project--run "opencode" ghostel-agent-opencode-command))

;;;###autoload
(defun ghostel-agent-project-cursor ()
  "Launch a Cursor agent in a ghostel terminal for the current project."
  (interactive)
  (ghostel-agent-project--run "cursor" ghostel-agent-cursor-command))

;;; Perspective command

;;;###autoload
(defun ghostel-agent-tab ()
  "Create or switch to a perspective showing AI agent ghostel buffers side-by-side.
If no agent buffers exist, display a message.  If the \"AI Agents\"
perspective already exists, switch to it and refresh the layout."
  (interactive)
  (let ((bufs (ghostel-agent-tab--buffers)))
    (if (null bufs)
        (message "No AI agent buffers")
      (persp-switch "AI Agents")
      (dolist (buf bufs)
        (persp-add-buffer buf))
      (ghostel-terminal-tab--layout bufs))))

(provide 'ghostel-agent-tab)
;;; ghostel-agent-tab.el ends here