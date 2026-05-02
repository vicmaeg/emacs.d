;;; ghostel-agent-tab.el --- Tab layout for AI agent ghostel buffers -*- lexical-binding: t; -*-

(require 'ghostel-terminal-tab)
(require 'ghostel)

;; Clean up old OSC 133 hooks if they were previously registered
(remove-hook 'ghostel-command-start-functions 'ghostel-agent-tab--on-command-start)
(remove-hook 'ghostel-command-finish-functions 'ghostel-agent-tab--on-command-finish)

(defvar-local ghostel-agent-tab--cursor-p nil
  "Non-nil when this ghostel buffer is a running Cursor agent.
Set when the buffer title contains `Cursor Agent' and cleared
when a shell prompt title appears (meaning the agent exited).")

(defun ghostel-agent-tab--shell-prompt-p (title)
  "Return non-nil if TITLE looks like a shell prompt.
Matches patterns like user@host:path."
  (string-match-p (rx (1+ (not (any "@"))) "@" (1+ (not (any ":"))) ":")
                  title))

(defun ghostel-agent-tab--set-title (title)
  "Custom title handler that preserves agent detection in buffer names.
Wraps `ghostel--set-title-default' to:
- Detect new Cursor agents from titles containing `Cursor Agent'
- Preserve `Cursor Agent' prefix while cursor is running
- Clear the cursor mark when a shell prompt title appears"
  (let* ((current-name (buffer-name))
         (is-cursor (or ghostel-agent-tab--cursor-p
                        (and current-name
                             (string-match-p "Cursor Agent" current-name)))))
    (cond
     ;; Cursor agent exited - shell prompt appeared (title doesn't contain Cursor Agent)
     ((and is-cursor
           (not (string-match-p "Cursor Agent" title))
           (ghostel-agent-tab--shell-prompt-p title))
      (setq-local ghostel-agent-tab--cursor-p nil)
      (ghostel--set-title-default title))
     ;; Cursor agent running - preserve prefix if title lost it
     (is-cursor
      (setq-local ghostel-agent-tab--cursor-p t)
      (unless (string-match-p "Cursor Agent" title)
        (setq title (format "Cursor Agent | %s" title)))
      (ghostel--set-title-default title))
     ;; New cursor agent detected from title
     ((string-match-p "Cursor Agent" title)
      (setq-local ghostel-agent-tab--cursor-p t)
      (ghostel--set-title-default title))
     ;; Not cursor - normal behavior
     (t
      (ghostel--set-title-default title)))))

(defun ghostel-agent-tab--detect (buffer)
  "Return the agent type for BUFFER, or nil if no agent is active.
Detects `opencode' from buffer name containing `OpenCode' or `OC |'.
Detects `cursor' from buffer name containing `Cursor Agent' or from
the buffer-local cursor flag."
  (let ((name (buffer-name buffer)))
    (cond
     ((string-match-p (rx (or "OpenCode" "OC |")) name) 'opencode)
     ((or (buffer-local-value 'ghostel-agent-tab--cursor-p buffer)
          (string-match-p "Cursor Agent" name))
      'cursor)
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

;;;###autoload
(defun ghostel-agent-tab ()
  "Create or switch to a tab showing AI agent ghostel buffers side-by-side.
If no agent buffers exist, display a message.  If the \"AI Agents\"
tab already exists, switch to it and refresh the layout."
  (interactive)
  (require 'ghostel)
  (let ((bufs (ghostel-agent-tab--buffers)))
    (if (null bufs)
        (message "No AI agent buffers")
      (if (ghostel-terminal-tab--tab-named-p "AI Agents")
          (tab-bar-switch-to-tab "AI Agents")
        (tab-bar-new-tab)
        (tab-bar-rename-tab "AI Agents"))
      (ghostel-terminal-tab--layout bufs))))

;; Install our custom title handler
(setq ghostel-set-title-function #'ghostel-agent-tab--set-title)

(provide 'ghostel-agent-tab)
;;; ghostel-agent-tab.el ends here