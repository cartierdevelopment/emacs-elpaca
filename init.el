;; -*- lexical-binding: t; -*-
(defvar elpaca-installer-version 0.9)
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
    (when (< emacs-major-version 28) (require 'subr-x))
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
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  (elpaca-use-package-mode))
(setq use-package-always-ensure t)

;; Save the command history
(savehist-mode 1)

;; Main window hacks
(set-fringe-mode 0)

(add-hook 'window-configuration-change-hook
          (lambda () (set-window-margins nil 2 2))) ;; Adjust values as needed

;; custom theme
;;(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")
;;(load-theme 'dracula t)

(elpaca ef-themes
  :ensure t
  ;;:defer 2 ;; Load 2 seconds after startup
  :config
  (load-theme 'ef-maris-light t))

;; Paid font
(set-face-attribute 'default nil
                    :family "Berkeley Mono"
                    :height 160
                    :weight 'normal)

(elpaca exec-path-from-shell
  :ensure t
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

(elpaca orderless
  :demand t
  :init
  (setq completion-styles '(orderless)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(elpaca vertico
  :ensure t
  :config
  (setq vertico-cycle t)
  (setq vertico-resize nil)
  (vertico-mode 1))

(elpaca marginalia
  :ensure t
  :config
  (marginalia-mode))

(elpaca consult
  :ensure t
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
  (add-hook 'go-mode-hook (lambda ()
                            (add-hook 'before-save-hook 'gofmt-before-save nil t)))
  (setq-default tab-width 8
                gofmt-command "goimports"
                indent-tabs-mode t))

;; Enable Flycheck for Go files
(elpaca flycheck
  (add-hook 'go-mode-hook 'flycheck-mode))

(elpaca dape
  (setq dape-buffer-window-arrangement 'right
        dape-inhibit-idle-timer t
        dape-debug-log-level 'info)

  (with-eval-after-load 'dape
    ;; Ensure dape-configs is available before modifying it
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
                   :args []))

    ;; Define keybindings for common debugging actions.
    (let ((map dape-mode-map))
      (define-key map (kbd "C-c d b") 'dape-breakpoint-toggle)
      (define-key map (kbd "C-c d c") 'dape-continue)
      (define-key map (kbd "C-c d n") 'dape-next)
      (define-key map (kbd "C-c d s") 'dape-step-in)
      (define-key map (kbd "C-c d o") 'dape-step-out)
      (define-key map (kbd "C-c d r") 'dape-restart)
      (define-key map (kbd "C-c d q") 'dape-quit))))


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
  :ensure nil  ; Built-in package
  :init
  (setq org-imenu-depth 7)
  :config
  ;; General Org settings.
  (setq org-agenda-files '("~/org/tasks.org"))  ; Set specific agenda file
  (setq org-todo-keywords '((sequence "TODO(t)" "WAIT(w!)" "|" "CANCEL(c!)" "DONE(d!)"))))

(use-package org-capture
  :ensure nil
  :bind ("C-c c" . org-capture)
  :config
  (defun my/org-capture-template (title file headline &optional extra-properties)
    "Generate an Org capture template with TITLE, FILE, HEADLINE, and EXTRA-PROPERTIES."
    (concat "* " title "\n"
            ":PROPERTIES:\n"
            ":CAPTURED: %U\n"
            ":CUSTOM_ID: h:%(format-time-string \"%Y%m%dT%H%M%S\")\n"
            (if extra-properties extra-properties "")
            ":END:\n\n"
            "%a\n%i%?"))

  (setq org-capture-templates
        `(("u" "Unprocessed" entry
           (file+headline "~/org/tasks.org" "Unprocessed")
           ,(my/org-capture-template "TODO %^{Title} %^g" "tasks.org" "Unprocessed")
           :empty-lines-after 1)
          ("w" "Wishlist" entry
           (file+olp "~/org/tasks.org" "Wishlist")
           ,(my/org-capture-template "WAIT %^{Title} %^g" "tasks.org" "Wishlist")
           :empty-lines-after 1))))

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)  ;; Use `gfm-mode` for README.md files
  :init
  (setq markdown-command "multimarkdown"))

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
  (setq denote-directory (expand-file-name "~/org/denote-markdown/"))
  (setq denote-file-type 'markdown-toml)

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

(elpaca
  (denote-search
    :url "https://github.com/lmq-10/denote-search"
    :ref :newest
    :bind
    (("C-c s s" . denote-search)
     ("C-c s d" . denote-search-marked-dired-files)
     ("C-c s r" . denote-search-files-referenced-in-region))
    :custom
    (denote-search-format-heading-function #'denote-search-format-heading-with-keywords)))

(elpaca denote-menu
  :ensure t
  :config
  (with-eval-after-load 'denote-menu
    (define-key denote-menu-mode-map (kbd "C-c z") 'list-denotes)
    (define-key denote-menu-mode-map (kbd "c") 'denote-menu-clear-filters)
    (define-key denote-menu-mode-map (kbd "/ r") 'denote-menu-filter)
    (define-key denote-menu-mode-map (kbd "/ k") 'denote-menu-filter-by-keyword)
    (define-key denote-menu-mode-map (kbd "/ o") 'denote-menu-filter-out-keyword)
    (define-key denote-menu-mode-map (kbd "e") 'denote-menu-export-to-dired)))

(elpaca gptel
  :ensure t
  :defer t  ;; Load only when first used
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

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(denote-search))
 '(package-vc-selected-packages
   '((denote-search :url "https://github.com/lmq-10/denote-search"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
