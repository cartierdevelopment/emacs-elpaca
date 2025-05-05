;; -*- lexical-binding: t; -*-

(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Save the command history
(savehist-mode 1)

;; Remember where we were last editing a file.

(save-place-mode 1)  

;; A cool mode to revert a window configuration
(winner-mode 1)

;; Set tab width to 8 spaces
(setq tab-width 8)

(setq org-hide-emphasis-markers t)

;; Set the wrap width (default is 70)

(setq-default fill-column 110)
(setq-default auto-fill-function 'do-auto-fill)

;; custom theme
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")
;;(load-theme 'dracula t)

; (elpaca ef-themes
;   :config
;   (load-theme 'ef-maris-light t))


;;; For packaged versions which must use `require'.
(elpaca modus-themes
  :ensure t
  :config
  ;; Add all your customizations prior to loading the themes
  (setq modus-themes-italic-constructs t
        modus-themes-bold-constructs nil)

  ;; Load the theme of your choice.
  (load-theme 'modus-operandi)

  (define-key global-map (kbd "<f5>") #'modus-themes-toggle))

(elpaca spacious-padding
  (spacious-padding-mode 1))

;; Paid font
(set-face-attribute 'default nil
                    :family "Berkeley Mono"
                    :height 170
                    :weight 'normal)

(elpaca exec-path-from-shell
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;; If we need other paths us the setting below:
;;(setq exec-path-from-shell-variables '("PATH" "MANPATH" "GOPATH" "PYTHONPATH"))
;;(exec-path-from-shell-initialize)

(when (executable-find "gls")
  (setq insert-directory-program (executable-find "gls")
        dired-use-ls-dired t
        dired-listing-switches "-al --group-directories-first"))

;;(elpaca org-superstar
;;(add-hook 'org-mode-hook (lambda () (org-superstar-mode 1))))

(elpaca orderless
  :demand t
  :init
  (setq completion-styles '(orderless)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(elpaca vertico
  :config
  (setq vertico-cycle t)
  (setq vertico-resize nil)
  (vertico-mode 1))

(elpaca marginalia
  :config
  (marginalia-mode 1))

(elpaca consult
  :config
  (with-eval-after-load 'consult
    (define-key consult-mode-map (kbd "C-x b") 'consult-buffer)  ;; Remap to consult-buffer
    (define-key consult-mode-map (kbd "M-s r") 'consult-ripgrep)  ;; Ripgrep search
    (define-key consult-mode-map (kbd "M-s f") 'consult-find)     ;; File search
    (define-key consult-mode-map (kbd "M-s F") 'consult-locate)   ;; Locate search
    (define-key consult-mode-map (kbd "M-s l") 'consult-line)     ;; Search for a line in the current buffer
    (define-key consult-mode-map (kbd "M-s y") 'consult-yank-pop)) ;; Yank-pop from kill-ring

  (setq consult-project-root-function
        (lambda ()
          (when-let (project (project-current))
            (car (project-roots project))))))  ;; Use project.el to retrieve the project root

(elpaca jinx)
;; Enable jinx globally
(add-hook 'emacs-startup-hook #'global-jinx-mode)

;; Keybinding for quick corrections in jinx buffers
(with-eval-after-load 'jinx
  (define-key jinx-mode-map (kbd "M-$") #'jinx-correct))

;; If using orderless for completion, integrate it with jinx
(with-eval-after-load 'orderless
  (add-to-list 'completion-category-overrides '(jinx (styles orderless))))

;; Languages

;; Install and configure js2-mode for Node.js development
(elpaca js2-mode
  (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
  (add-hook 'js2-mode-hook (lambda ()
                             (setq js-indent-level 2
                                   js2-basic-offset 2))))

;; Install and configure PHP mode
(elpaca php-mode
  (add-to-list 'auto-mode-alist '("\\.php\\'" . php-mode)))

;; Install and configure Go mode
(elpaca go-mode
  (add-hook 'go-mode-hook
            (lambda ()
              (add-hook 'before-save-hook #'gofmt-before-save nil t)))
  (setq-default tab-width 8
                gofmt-command "goimports"
                indent-tabs-mode t))

;; Enable Flycheck for Go files
(elpaca flycheck
  (add-hook 'go-mode-hook #'flycheck-mode))

(use-package dape
  :defer t
  :ensure t
  :after go-mode
  :custom
  ;; Arrange debug windows on the right.
  (dape-buffer-window-arrangement 'right)
  ;; Improve performance during debugging.
  (dape-inhibit-idle-timer t)  ;; Disable idle timers during debugging
  (dape-debug-log-level 'info)  ;; Set log level to avoid excessive logging
  :config
  ;; Add a Dape debugging configuration for Go using Delve (dlv).
  (add-to-list 'dape-configs
               `(go-debug-main
                 modes (go-mode go-ts-mode)
                 command ,(or (executable-find "dlv") "dlv")  ;; Use `dlv` from PATH
                 command-args ("dap" "--listen" "127.0.0.1::autoport")
                 command-cwd dape-command-cwd
                 port :autoport
                 :type "debug"
                 :request "launch"
                 :name "Debug Go Program"
                 :cwd "."
                 :program "."
                 :args [])))

;; Define `C-c d` as a prefix key.
(defvar dape-prefix-map (make-sparse-keymap)
  "Keymap for Dape prefix commands.")
(define-key global-map (kbd "C-c d") dape-prefix-map)

;; Additional Functions

;; Start debugging the current Go program.
(defun my/start-go-debug ()
  "Start debugging the current Go program."
  (interactive)
  (dape 'go-debug-main))
(define-key dape-prefix-map (kbd "d") #'my/start-go-debug)

;; Toggle Dape debug mode.
(defun my/toggle-debug-mode ()
  "Toggle Dape debug mode."
  (interactive)
  (if (bound-and-true-p dape-mode)
      (dape-mode -1)
    (dape-mode 1)))
(define-key dape-prefix-map (kbd "t") #'my/toggle-debug-mode)

;; Set a breakpoint at the current line.
(defun my/set-breakpoint ()
  "Set a breakpoint at the current line."
  (interactive)
  (dape-breakpoint-toggle))
(define-key dape-prefix-map (kbd "b") #'my/set-breakpoint)



(elpaca (transient :upgrade t))  ;; Ensure transient is up-to-date
(elpaca magit
  (global-set-key (kbd "C-x g") 'magit-status))  ;; Bind `magit-status` to `C-x g`

(elpaca ace-window
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
        aw-ignore-current nil  ;; Ensure the current window gets a label
        aw-dispatch-always t   ;; Always show dispatch menu
        aw-dispatch-when-more-than 3)  ;; Only show dispatch options when >3 windows

  ;; Use `with-eval-after-load` to ensure `ace-window` is loaded before setting the face
  (with-eval-after-load 'ace-window
    (set-face-attribute 'aw-leading-char-face nil
                        :height 1.5
                        :foreground "orangered2"
                        :weight 'bold))

  ;; Bind keys
  (define-key global-map (kbd "M-o") 'ace-window)   ;; Main binding
  (define-key global-map (kbd "C-x o") 'ace-window) ;; Override default window switching
  (define-key global-map (kbd "C-x 4 D") 'ace-delete-window)
  (define-key global-map (kbd "C-x 4 s") 'ace-swap-window)
  (define-key global-map (kbd "C-x 4 l") 'aw-flip-window))

(elpaca eglot
  ;; Hook to ensure eglot is activated for Go modes
  (add-hook 'go-mode-hook #'eglot-ensure)
  (add-hook 'go-ts-mode-hook #'eglot-ensure)

  ;; Custom settings for eglot
  (setq eglot-events-buffer-size 0    ;; Show full logs if needed
        eglot-send-changes-idle-time 0.5)  ;; Faster response from `gopls`

  ;; Bindings for eglot actions
  (with-eval-after-load 'eglot
    (define-key eglot-mode-map (kbd "C-c r") 'eglot-rename)
    (define-key eglot-mode-map (kbd "C-c a") 'eglot-code-actions)))

;; Org mode

(elpaca org
  :init
  (setq org-imenu-depth 7)
  :config
  ;; General Org settings.
  (setq org-agenda-files '("~/org/tasks.org"))  ; Set specific agenda file
  (setq org-todo-keywords '((sequence "TODO(t)" "WAIT(w!)" "|" "CANCEL(c!)" "DONE(d!)" "BACKLOG(b!)")))


(setopt org-agenda-remove-tags t)
(setopt org-agenda-restore-windows-after-quit t)
(setopt org-agenda-show-inherited-tags nil)
(setopt org-agenda-skip-deadline-if-done t)
(setopt org-agenda-skip-scheduled-if-done t)
(setopt org-agenda-skip-timestamp-if-done t)
(setopt org-agenda-sorting-strategy
	'((agenda time-up deadline-up scheduled-up todo-state-up priority-down)
	  (todo todo-state-down priority-down deadline-up)
	  (tags todo-state-down priority-down deadline-up)
	  (search todo-state-down priority-down deadline-up)))
(setopt org-agenda-tags-todo-honor-ignore-options t)
(setopt org-agenda-use-tag-inheritance nil)
(setopt org-agenda-window-frame-fractions '(0.0 . 0.5))
(setopt org-agenda-deadline-faces
	'((1.0001 . org-warning)              ; due yesterday or before
	  (0.0    . org-upcoming-deadline)))  ; due today or later



  (setopt org-todo-keywords
  '((sequence "ONGO(o)" "TODO(t)" "PLAN(p)" "WAIT(w)" "|" "DONE(d)" "SKIP(s)")))
  (setopt org-tag-alist
	'((:startgroup)
	  ("Handson" . ?o)
	  (:grouptags)
	  ("Write" . ?w) ("Code" . ?c)
	  (:endgroup)

	  (:startgroup)
	  ("Handsoff" . ?f)
	  (:grouptags)
	  ("Read" . ?r) ("Watch" . ?W) ("Listen" . ?l)
	  (:endgroup)))



(let ((org-agenda-week-span 7)
      (default-grid '((org-agenda-use-time-grid nil)))
      (ignore-appt '((org-agenda-category-filter-preset '("-RDV" "-RDL"))
                     (org-agenda-use-time-grid nil)))
      (work-only '((org-agenda-category-filter-preset '("+MLL"))))
      (nonwork-only '((org-agenda-category-filter-preset '("-MLL")))))

  (setopt org-agenda-custom-commands
          `(
            ;; 📁 Archiving
            ("#" "Archive candidates" todo "DONE|SKIP")

            ;; 🧠 Ongoing Tasks: Hands-on vs Hands-off
            ("A" "Hands-on (Write/Code)" tags-todo "+TAGS={Write\\|Code}+TODO=\"ONGO\"")
            ("Z" "Hands-off (Read/Listen/Watch)" tags-todo "+TAGS={Read\\|Listen\\|Watch}+TODO=\"ONGO\"")

            ;; 📆 Weekly Appointments
            ("$" "Appointments this week" agenda* "")

            ;; 📌 Scheduled/Deadline Tasks This Week
            ("ù" . "This week's scheduled/deadline tasks")
            ("ùù" "All non-appt tasks" agenda "" ,ignore-appt)
            ("ù," "Work-related tasks (MLL)" agenda "" ,(append work-only ignore-appt))
            ("ù?" "Personal tasks (-MLL)" agenda "" ,(append nonwork-only ignore-appt))

            ;; 🔜 Ongoing & TODOs
            ("*" . "Next Actions")
            ("**" "All ONGO/TODO" tags-todo "TODO={ONGO\\|TODO}")
            ("*," "Work ONGO/TODO (MLL)" tags-todo "TODO={ONGO\\|TODO}" ,work-only)
            ("*?" "Personal ONGO/TODO (-MLL)" tags-todo "TODO={ONGO\\|TODO}" ,nonwork-only)

            ;; 📝 PLAN tasks with no SCHEDULED/DEADLINE
            (";" . "Planning Ahead")
            (";;" "All PLAN (unscheduled)" tags-todo "TODO=\"PLAN\"+DEADLINE=\"\"+SCHEDULED=\"\"")
            (";," "Work PLAN (MLL)" tags-todo "TODO=\"PLAN\"+DEADLINE=\"\"+SCHEDULED=\"\"" ,work-only)
            (";?" "Personal PLAN (-MLL)" tags-todo "TODO=\"PLAN\"+DEADLINE=\"\"+SCHEDULED=\"\"" ,nonwork-only)

            ;; ⏳ WAIT tasks with no SCHEDULED/DEADLINE
            (":" . "Waiting On")
            ("::" "All WAIT (unscheduled)" tags-todo "TODO=\"WAIT\"+DEADLINE=\"\"+SCHEDULED=\"\"")
            (":," "Work WAIT (MLL)" tags-todo "TODO=\"WAIT\"+DEADLINE=\"\"+SCHEDULED=\"\"" ,work-only)
            (":?" "Personal WAIT (-MLL)" tags-todo "TODO=\"WAIT\"+DEADLINE=\"\"+SCHEDULED=\"\"" ,nonwork-only)

            ;; ⏰ Upcoming Deadlines (60d window)
            ("!" . "Deadline Radar")
            ("!!" "All deadlines" agenda ""
             ((org-agenda-span 1)
              (org-deadline-warning-days 60)
              (org-agenda-entry-types '(:deadline))))
            ("!," "Work deadlines (MLL)" agenda ""
             ((org-agenda-span 1)
              (org-agenda-category-filter-preset '("+MLL"))
              (org-deadline-warning-days 60)
              (org-agenda-entry-types '(:deadline))))
            ("!?" "Personal deadlines (-MLL)" agenda ""
             ((org-agenda-span 1)
              (org-agenda-category-filter-preset '("-MLL"))
              (org-deadline-warning-days 60)
              (org-agenda-entry-types '(:deadline))))
            )))

            (setopt org-agenda-sorting-strategy
            '((agenda time-up deadline-up scheduled-up todo-state-up priority-down)
            (todo todo-state-up priority-down deadline-up)
            (tags todo-state-up priority-down deadline-up)
            (search todo-state-up priority-down deadline-up)))
)


;; end of new config.


(use-package org-capture
  :ensure nil
  :bind ("C-c c" . org-capture)
  :config
  (defun my/org-capture-template (title &optional extra-properties)
    "Generate an Org capture template with TITLE and EXTRA-PROPERTIES."
    (concat "* " title "\n"
            ":PROPERTIES:\n"
            ":CAPTURED: %U\n"
            ":CUSTOM_ID: h:%(format-time-string \"%Y%m%dT%H%M%S\")\n"
            (if (and extra-properties (not (string-empty-p extra-properties)))
                (concat extra-properties "\n") "")
            ":END:\n\n"
            "%a\n%i%?"))

(setopt org-capture-templates
	'(("r" "RDV Perso" entry (file+headline "~/org/tasks.org" "RDV Perso")
	   "* RDV avec %:fromname %?\n  SCHEDULED: %^T\n  :PROPERTIES:\n  :CAPTURED: %U\n  :END:\n\n- %a" :prepend t)
	  ("!" "RDV MLL" entry (file+headline "~/org/tasks.org" "RDV MLL")
	   "* RDV avec %:fromname %?\n  SCHEDULED: %^T\n  :PROPERTIES:\n  :CAPTURED: %U\n  :END:\n\n- %a" :prepend t)
	  ("d" "Divers" entry (file+headline "~/org/tasks.org" "Divers")
	   "* TODO %?\n  :PROPERTIES:\n  :CAPTURED: %U\n  :END:\n\n- %a" :prepend t)
	  ("D" "Divers (read)" entry (file+headline "~/org/tasks.org" "Divers")
	   "* TODO %a :Read:" :prepend t :immediate-finish t)
	  ("m" "Mission" entry (file+headline "~/org/tasks.org" "Mission")
	   "* TODO %?\n  :PROPERTIES:\n  :CAPTURED: %U\n  :END:\n\n- %a\n\n%i" :prepend t)
	  ("M" "Mission (read)" entry (file+headline "~/org/tasks.org" "Mission")
	   "* TODO %a :Read" :prepend t :immediate-finish t))))

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)  ;; Use `gfm-mode` for README.md files
  :init
  (setq markdown-command "multimarkdown"))


;;(use-package howm
;;  :ensure t
;;  :init
;;  (setq howm-directory "~/org/howm")
;;  ;; What format to use for the files?
;;  (setq howm-file-name-format "%Y-%m-%d-%H%M%S.md")
;;  (setq howm-view-title-header "*")
;;  (setq howm-dtime-format "<%Y-%m-%d %a %H:%M>")
;;  ;; Avoid conflicts with Org-mode by changing Howm's prefix from "C-c ,".
;;  (setq howm-prefix (kbd "C-c ;")))

;; Keep one window after "1" key in the summary buffer.
;;(setq howm-view-keep-one-window t)

;; Use ripgrep as grep
  (setq howm-view-use-grep t)
  (setq howm-view-grep-command "rg")
  (setq howm-view-grep-option "-nH --no-heading --color never")
  (setq howm-view-grep-extended-option nil)
  (setq howm-view-grep-fixed-option "-F")
  (setq howm-view-grep-expr-option nil)
  (setq howm-view-grep-file-stdin-option nil)

(elpaca denote
  ;; Hooks for Denote functionality
  (add-hook 'text-mode-hook 'denote-fontify-links-mode-maybe)
  (add-hook 'dired-mode-hook 'denote-dired-mode)

  ;; Keybindings for Denote actions
  (define-key global-map (kbd "C-c n n") 'denote)                ;; Create a new note
  (define-key global-map (kbd "C-c n d") 'denote-sort-dired)     ;; Sort notes in Dired
  (define-key global-map (kbd "C-c n l") 'denote-link)           ;; Insert a link to a note
  (define-key global-map (kbd "C-c n L") 'denote-add-links)      ;; Add links to a note
  (define-key global-map (kbd "C-c n b") 'denote-backlinks)      ;; Show backlinks
  (define-key global-map (kbd "C-c n r") 'denote-rename-file)    ;; Rename a note file
  (define-key global-map (kbd "C-c n R") 'denote-rename-file-using-front-matter) ;; Rename using front matter

  ;; Dired mode bindings
  (with-eval-after-load 'dired
    (define-key dired-mode-map (kbd "C-c C-d C-i") 'denote-dired-link-marked-notes)  ;; Link marked notes
    (define-key dired-mode-map (kbd "C-c C-d C-r") 'denote-dired-rename-files)       ;; Rename files
    (define-key dired-mode-map (kbd "C-c C-d C-k") 'denote-dired-rename-marked-files-with-keywords) ;; Rename with keywords
    (define-key dired-mode-map (kbd "C-c C-d C-R") 'denote-dired-rename-marked-files-using-front-matter)) ;; Rename using front matter

  ;; Configuration settings for Denote
  (setq denote-directory (expand-file-name "~/org/notes/"))
  ;;(setq denote-file-type 'markdown-toml)

  ;; Ensure Denote directory exists
  (unless (file-directory-p denote-directory)
    (make-directory denote-directory t))

  ;; Keywords configuration
  (setq denote-known-keywords
        (split-string (shell-command-to-string "grep -ohP '(?<=#\\+keywords: ).*' ~/Documents/notes/* | sort -u") "\n" t))
  (setq denote-infer-keywords t
        denote-sort-keywords t
        denote-prompts '(title keywords)
        denote-excluded-directories-regexp nil
        denote-excluded-keywords-regexp nil
        denote-rename-confirmations '(rewrite-front-matter modify-file-name))

  ;; Org’s date picker for date prompts
  (setq denote-date-prompt-use-org-read-date t)

  ;; Backlinks context
  (setq denote-backlinks-show-context t)

  ;; Rename Denote buffers dynamically
  (denote-rename-buffer-mode 1))

;;(elpaca
;;  (denote-search
;;    :url "https://github.com/lmq-10/denote-search"
;;    :ref :newest
;;    :bind
;;    (("C-c s s" . denote-search)
;;     ("C-c s d" . denote-search-marked-dired-files)
;;     ("C-c s r" . denote-search-files-referenced-in-region))
;;    :custom
;;    (denote-search-format-heading-function #'denote-search-format-heading-with-keywords)))

;;(use-package denote-menu
;;  :ensure t
;;  :bind (("C-c z" . list-denotes)
;;         :map denote-menu-mode-map
;;         ("c" . denote-menu-clear-filters)
;;         ("/ r" . denote-menu-filter)
;;         ("/ k" . denote-menu-filter-by-keyword)
;;         ("/ o" . denote-menu-filter-out-keyword)
;;         ("e" . denote-menu-export-to-dired)))
;;
(elpaca gptel
)

;; Custom functions and bindings
(global-set-key (kbd "s-q") 'save-buffers-kill-terminal) ;; Cmd+Q to quit

(defun now ()
  "Insert string for the current time formatted like '2:34 PM'."
  (interactive)                 ; permit invocation in minibuffer
  (insert (format-time-string "%D %-I:%M %p")))


(defun today ()
  "Insert string for today's date nicely formatted in American style,
e.g. Sunday, September 17, 2000."
  (interactive)                 ; permit invocation in minibuffer
  (insert (format-time-string "%A, %B %e, %Y")))

;; Bindings
(global-set-key [f1] 'markdown-toggle-markup-hiding)
(global-set-key [f7] 'org-tags-view)


(global-set-key (kbd "C-c d") (lambda () 
  (interactive)
  (org-todo "DONE")))

(global-set-key (kbd "C-c a") 'org-agenda)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("5e39e95c703e17a743fb05a132d727aa1d69d9d2c9cde9353f5350e545c793d4"
     "fbf73690320aa26f8daffdd1210ef234ed1b0c59f3d001f342b9c0bbf49f531c" default))
 '(package-selected-packages nil)
 '(package-vc-selected-packages
   '((denote-search :url "https://github.com/lmq-10/denote-search"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
