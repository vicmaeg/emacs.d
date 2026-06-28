;;; my-connect-rds-pgmacs.el --- Connect to RDS PostgreSQL via PGmacs -*- lexical-binding: t; -*-

;; Commentary:
;;
;; Provides the interactive command `my/connect-rds-pgmacs', which is the
;; PGmacs counterpart to `my/connect-rds'.  It prompts for an environment
;; and a database, runs the same external script to fetch credentials, but
;; opens the database in PGmacs (a widget-based table browser/editor) instead
;; of a psql SQLi buffer.
;;
;; PGmacs connects using the pure-Emacs `pg-el' TCP client rather than a
;; `psql' subprocess, so it does not depend on psql being installed.  It is
;; better suited to browsing tables and inspecting individual rows (including
;; JSONB values, which it renders with a dedicated formatter), while the psql
;; path (`my/connect-rds') remains preferable for running scripts and sending
;; SQL from `.sql' files.
;;
;; This file reuses the script runner, credential parser, and customizable
;; variables defined in `my-connect-rds.el'; it adds only the PGmacs
;; connection logic.  `pg' and `pgmacs' are required lazily inside the
;; command body so that the psql path never depends on PGmacs being
;; installed.  The connection is made via `pg-connect-plist' (the pg-el
;; TCP client) and handed to `pgmacs-open'.
;;
;; See `my-connect-rds-usage.org' for a comparison of the two approaches and
;; the PGmacs keybindings.

;;; Code:

(require 'my-connect-rds)

(declare-function pg-connect-plist "pg")
(declare-function pgmacs-open "pgmacs")

;;;###autoload
(defun my/connect-rds-pgmacs (environment database)
  "Connect to an RDS PostgreSQL database via PGmacs.

Prompt for ENVIRONMENT and DATABASE (using the same customizable
lists as `my/connect-rds'), run `my/connect-rds-script' to fetch
credentials, and open the database in PGmacs.

PGmacs provides a widget-based table browser: the main buffer lists
all tables in the database, and you can open a table to browse its
rows paginated, edit cell values with RET, copy a row as JSON with
`j', export to CSV, and more.  See `my-connect-rds-usage.org' for
the keybinding reference.

Unlike `my/connect-rds', this command does not use `psql'; it
connects over TCP using the pure-Emacs `pg-el' library.  Note that
PGmacs uses GnuTLS for encrypted connections, which may be
incompatible with some hosted services that expect OpenSSL (see the
PGmacs README for details).

`pgmacs' is loaded lazily so that this command only requires it
when invoked; the psql path (`my/connect-rds') works without
PGmacs installed."
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
         (port     (plist-get creds :port)))
    (require 'pg)
    (require 'pgmacs)
    (let ((con (pg-connect-plist database user
                                 :password password
                                 :host host
                                 :port port)))
      (pgmacs-open con))
    (message "PGmacs connected to %s/%s as %s@%s:%s"
             environment database user host port)))

(provide 'my-connect-rds-pgmacs)
;;; my-connect-rds-pgmacs.el ends here
