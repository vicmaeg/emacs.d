;;; ghostel-agent-project.el --- Launch AI agents in ghostel terminals for projects -*- lexical-binding: t; -*-

(require 'project)
(require 'ghostel)

;;; Customizable agent commands

(defcustom ghostel-agent-opencode-command "opencode"
  "Command string sent to the shell to launch the OpenCode agent."
  :type 'string
  :group 'ghostel)

(defcustom ghostel-agent-cursor-command "agent"
  "Command string sent to the shell to launch the Cursor agent."
  :type 'string
  :group 'ghostel)

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

(provide 'ghostel-agent-project)
;;; ghostel-agent-project.el ends here
