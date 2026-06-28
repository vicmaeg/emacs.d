;;; my-connect-rds.el --- Connect to RDS PostgreSQL from Emacs -*- lexical-binding: t; -*-

;; Commentary:
;;
;; Provides the interactive command `my/connect-rds', which prompts for an
;; environment and a database, runs an external script to fetch credentials,
;; and opens a ready-to-use PostgreSQL SQLi buffer (`sql-interactive-mode')
;; without prompting for login parameters.
;;
;; The external script (see `my/connect-rds-script') receives the environment
;; and database as arguments and must print, one per line, the connection
;; parameters in this format (separator may be `=' or `:'):
;;
;;     Host=<host>
;;     User=<user>
;;     Password=<password>
;;     Port=<port>            ;; optional; defaults to `my/connect-rds-port'
;;
;; The password is delivered to `psql' through the `PGPASSWORD' environment
;; variable of the spawned process and is never stored in
;; `sql-connection-alist', `custom.el', or any other persistent location.
;;
;; For a usage guide covering the SQLi buffer, sending SQL from `.sql' files,
;; multiple simultaneous connections, and local testing, see the companion
;; file `my-connect-rds-usage.org'.

;;; Code:

(require 'sql)

;;; Customizable variables

(defcustom my/connect-rds-script "~/.local/bin/connect-rds.sh"
  "Path to the script that prints RDS connection parameters to stdout.

The script is invoked as `SCRIPT ENVIRONMENT DATABASE' and must emit
lines of the form `KEY=VALUE' (or `KEY:VALUE'), one per line.
Recognized keys are `Host', `User', `Password', and `Port' (the last
is optional).  Any other output is ignored."
  :type 'file
  :group 'my-connect-rds)

(defcustom my/connect-rds-environments
  '("local" "dev" "test" "acc" "box" "prod")
  "List of known environments offered during `my/connect-rds'.

`local' targets the Docker Compose stack in the repository root and
the sample `~/.local/bin/connect-rds.sh' for offline testing.

Free input is also accepted, so ad-hoc values can be typed without
customizing this list."
  :type '(repeat string)
  :group 'my-connect-rds)

(defcustom my/connect-rds-databases
  '("kyc" "vpm" "identitystore" "configuration")
  "List of known databases offered during `my/connect-rds'.

Free input is also accepted, so ad-hoc values can be typed without
customizing this list."
  :type '(repeat string)
  :group 'my-connect-rds)

(defcustom my/connect-rds-port 5432
  "Default PostgreSQL port when the script does not emit a `Port' line."
  :type 'integer
  :group 'my-connect-rds)

;;; Credential parsing

(defun my/connect-rds--split-line (line)
  "Split LINE into (KEY . VALUE) on the first `=' or `:'.
Return nil if neither separator is present or VALUE is empty."
  (let ((sep (or (string-match-p "=" line) (string-match-p ":" line))))
    (when sep
      (let ((key (string-trim (substring line 0 sep)))
            (val (string-trim (substring line (1+ sep)))))
        (unless (string-empty-p val)
          (cons (downcase key) val))))))

(defun my/connect-rds--parse-credentials (output)
  "Parse connection parameters from script OUTPUT.
OUTPUT is the script's stdout as a string.  Return a plist with keys
:host, :user, :password, and :port (an integer).  Raise an error if
Host, User, or Password is missing."
  (let ((host nil) (user nil) (password nil) (port nil))
    (dolist (line (split-string output "\n"))
      (let ((kv (my/connect-rds--split-line (string-trim line))))
        (when kv
          (pcase (car kv)
            ("host"     (setq host     (cdr kv)))
            ("user"     (setq user     (cdr kv)))
            ("password" (setq password (cdr kv)))
            ("port"     (setq port     (cdr kv)))))))
    (unless host     (error "connect-rds: Host missing from script output"))
    (unless user     (error "connect-rds: User missing from script output"))
    (unless password (error "connect-rds: Password missing from script output"))
    (list :host host
          :user user
          :password password
          :port (if port (string-to-number port) my/connect-rds-port))))

;;; Script execution

(defconst my/connect-rds--wsl-chrome
  "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
  "Windows Chrome path used as BROWSER when Emacs runs inside WSL.")

(defun my/connect-rds--wsl-p ()
  "Return non-nil when Emacs is running inside WSL."
  (and (eq system-type 'gnu/linux)
       (let ((proc-version
              (ignore-errors
                (with-temp-buffer
                  (insert-file-contents "/proc/version")
                  (buffer-string)))))
         (and proc-version
              (or (string-match-p "Microsoft" proc-version)
                  (string-match-p "WSL" proc-version))))))

(defun my/connect-rds--process-environment ()
  "Return `process-environment' for the connect-rds script subprocess.
On WSL, prepend BROWSER pointing at Windows Chrome so AWS SSO can
open a login page from non-interactive `call-process' runs."
  (if (and (my/connect-rds--wsl-p)
           (file-exists-p my/connect-rds--wsl-chrome))
      (cons (cons "BROWSER" my/connect-rds--wsl-chrome)
            process-environment)
    process-environment))

(defun my/connect-rds--run-script (environment database)
  "Run `my/connect-rds-script' for ENVIRONMENT and DATABASE.
Return the script's stdout.  Raise an error with stderr context if the
script exits non-zero or is not executable.

`call-process' is used so the arguments are passed directly to the
script (no shell); they are therefore not shell-quoted.  On WSL,
`my/connect-rds--process-environment' sets BROWSER to Windows Chrome
so AWS SSO can launch a browser during credential fetch."
  (let ((script (expand-file-name my/connect-rds-script))
        (stderr-file (make-temp-file "connect-rds-"))
        exit stderr stdout)
    (unless (file-executable-p script)
      (ignore-errors (delete-file stderr-file))
      (error "connect-rds: script not executable: %s" script))
    (unwind-protect
        (with-temp-buffer
          (let ((process-environment (my/connect-rds--process-environment)))
            (setq exit (call-process script nil (list t stderr-file) nil
                                      environment database)))
          (setq stdout (string-trim (buffer-string)))
          (setq stderr (with-temp-buffer
                         (insert-file-contents stderr-file)
                         (string-trim (buffer-string)))))
      (ignore-errors (delete-file stderr-file)))
    (unless (eq exit 0)
      (error "connect-rds: script failed (exit %s): %s"
             exit (if (string-empty-p stderr) "(no stderr)" stderr)))
    stdout))

;;; Interactive command

;;;###autoload
(defun my/connect-rds (environment database)
  "Connect to an RDS PostgreSQL database in Emacs.

Prompt for ENVIRONMENT and DATABASE, then run `my/connect-rds-script'
to fetch credentials and open a SQLi buffer ready to receive SQL.

The resulting buffer is named `*SQL: ENVIRONMENT DATABASE*' and runs
`sql-interactive-mode' (a `comint'-based `psql' session).  If a buffer
with that name already exists but its process is dead, it is killed
before connecting; a live session is reused as-is.

The password reaches `psql' via the `PGPASSWORD' environment variable
and is never persisted.  See `my-connect-rds-usage.org' for the full
guide, including sending SQL from `.sql' files."
  (interactive
   (let ((env (completing-read "Environment: "
                               my/connect-rds-environments nil nil))
         (db  (completing-read "Database: "
                               my/connect-rds-databases nil nil)))
     (list env db)))
  (let* ((output (my/connect-rds--run-script environment database))
         (creds  (my/connect-rds--parse-credentials output))
         (host     (plist-get creds :host))
         (user     (plist-get creds :user))
         (password (plist-get creds :password))
         (port     (plist-get creds :port))
         (buf-name (format "*SQL: %s %s*" environment database))
         (existing (get-buffer buf-name)))
    ;; Reuse a live session; replace a dead buffer so `sql-product-interactive'
    ;; does not allocate a `*SQL: ...-1*' name.
    (when (and existing (not (get-buffer-process existing)))
      (kill-buffer existing))
    ;; `sql-product-interactive' reads (default-value 'sql-server) etc.,
    ;; not the dynamically-bound value.  A `let' binding only affects
    ;; `default-value' when the current buffer has no buffer-local binding
    ;; for the variable.  `sql-interactive-mode' makes sql-server/user/port/
    ;; database buffer-local (sql.el:4297-4300), so a second call issued
    ;; from within a SQLi buffer would read stale global defaults instead
    ;; of the `let'-bound values.  Switching to a clean hidden buffer
    ;; (which never runs `sql-interactive-mode') avoids this pitfall.
    ;; Binding `sql-postgres-login-params' to nil suppresses every
    ;; interactive login prompt.  Postgres does not pass the password on
    ;; the command line and has no `:password-in-comint' interception, so
    ;; the password is supplied via `PGPASSWORD' in `process-environment'.
    (with-current-buffer (get-buffer-create " *my-connect-rds*")
      (let ((sql-postgres-login-params nil)
            (sql-user     user)
            (sql-server   host)
            (sql-database database)
            (sql-port     port)
            (sql-product  'postgres)
            ;; Pretty-print options scoped to RDS sessions only.  The pager
            ;; is unusable inside a comint buffer, expanded mode lays out
            ;; one column per line (essential for long JSONB values), and
            ;; unicode borders improve readability.
            (sql-postgres-options
             '("-P" "pager=off"
               "-P" "expanded=on"
               "-P" "border=2"
               "-P" "linestyle=unicode"))
            (process-environment
             (cons (format "PGPASSWORD=%s" password) process-environment)))
        (sql-product-interactive 'postgres
                                 (format "%s %s" environment database))))
    (message "Connected to %s/%s as %s@%s:%s"
             environment database user host port)))

(provide 'my-connect-rds)
;;; my-connect-rds.el ends here
