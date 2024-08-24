;;; github-tool.el --- Emacs Lisp Compatibility Library -*- lexical-binding: t; -*-

;; Author: Wurly <48784425+wurly200a@users.noreply.github.com>
;; Version: 0.0.1
;; Package-Requires: ((emacs "29"))
;; Keywords: lisp
;; Homepage: https://github.com/wurly200a/github-tool.el

;;; Commentary:

;;; Code:
(require 'gh)
(require 'gh-repos)

(provide 'github-tool)

;;
;; Variables
;;
(defvar github-tool-current-buffer nil
  "Current buffer.")
(defvar github-tool-select-mode-map (make-sparse-keymap)
  "Keymap used in github-tool select mode.")

;; Key mapping of github-tool-select-mode.
(define-key github-tool-select-mode-map "\C-m" 'github-tool-select-item)
(define-key github-tool-select-mode-map "u" 'github-tool-list-display-user)
(define-key github-tool-select-mode-map "f" 'github-tool-list-display-starred)
(define-key github-tool-select-mode-map "o" 'github-tool-list-display-org)
(define-key github-tool-select-mode-map "p" 'previous-line)
(define-key github-tool-select-mode-map "n" 'next-line)

(defconst github-tool-list-buffer-name "*github-tool*")
(defconst github-tool-process-buffer-name "*github-tool-process*")

(defun github-tool-list-display-internal (repo-fetch-fn)
  "Display repositories using the provided REPO-FETCH-FN."
  (let ((buffer-for-display (get-buffer-create github-tool-list-buffer-name)))
    (with-current-buffer buffer-for-display
      (erase-buffer)
      (let* ((api (gh-repos-api "api" :sync t))
             (repos (funcall repo-fetch-fn api))
             (repo-list (oref repos :data)))

        (setq repo-list (sort repo-list
                              (lambda (a b)
                                (string< (oref a :name) (oref b :name)))))

        (dolist (repo repo-list)
          (let ((repo-name (oref repo :name))
                (repo-url (oref repo :html-url)))
            ;; Create a clickable button for the repository URL
            (insert-text-button
             repo-name
             'action (lambda (_)
                       (browse-url repo-url))
             'follow-link t)
            (insert (format " - %s\n" repo-url)))))
      (pop-to-buffer buffer-for-display)
      (github-tool-select-mode))))

(defun github-tool-list-display-user ()
  "Display the authenticated user's repositories with clickable URLs."
  (interactive)
  (github-tool-list-display-internal #'gh-repos-user-list))

(defun github-tool-list-display-starred ()
  "Display the authenticated user's starred repositories with clickable URLs."
  (interactive)
  (github-tool-list-display-internal #'gh-repos-starred-list))

(defun github-tool-list-display-org ()
  "Display the authenticated user's organization repositories with clickable URLs."
  (interactive)
  (github-tool-list-display-internal #'gh-repos-org-list))

(defun github-tool-select-item ()
  "Select the item."
  (interactive)

  (let (start-point end-point temp-line temp-list)
    (beginning-of-line)
    (setq start-point (point))
    (end-of-line)
    (setq end-point (point))
    (setq temp-line (buffer-substring start-point end-point))
    (setq temp-list (split-string temp-line " "))
    (switch-to-buffer (car temp-list))
    (goto-char (string-to-number (car (cdr temp-list))))
    )
)

;; make github-tool select-mode
(defun github-tool-select-mode ()
  "Major mode for choosing the item from list.

Select the item.
	\\[github-tool-select-item]

Key definitions:
\\{github-tool-select-mode-map}
Turning on Github-Tool-Select mode calls the value of the variable
`github-tool-select-mode-hook' with no args, if that value is non-nil."
  (interactive)
;  (message "github-tool-select-mode")
  (kill-all-local-variables)
  (use-local-map github-tool-select-mode-map)
  (setq buffer-read-only t
        truncate-lines t
        major-mode 'github-tool-select-mode
        mode-name "Github-Tool-Select")
  (setq github-tool-current-buffer (current-buffer))
  (goto-char (point-min))
  (message "[github-tool list] %d lines" (count-lines (point-min) (point-max)))
;  (setq hl-line-face 'underline)
  (hl-line-mode 1)
  (run-hooks 'github-tool-select-mode-hook)
)

;;; github-tool.el ends here
