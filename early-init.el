;;; early-init.el --- Early Init File -*- lexical-binding: t; no-byte-compile: t -*-
(setq package-enable-at-startup nil)
;; ===================
;; Measure and display startup time
;; ===================
(defun efs/display-startup-time ()
  "Display the Emacs startup time and number of garbage collections."
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'efs/display-startup-time)

;; ===================
;; Optimize garbage collection
;; ===================
;; Temporarily increase the garbage collection threshold for faster startup.
(setq gc-cons-threshold most-positive-fixnum)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 1000 1000 8))))  ;; Reset to 8 MB


;; Prevent Emacs from automatically modifying your `.emacs` configuration file 
(setq disabled-command-function nil)

;; ===================
;; Frame and window settings
;; ===================
(setq frame-resize-pixelwise t
      frame-inhibit-implied-resize t
      frame-title-format '("%b")
      initial-frame-alist '((width . 150) (height . 57))
      default-frame-alist '((width . 150) (height . 57)))

;; Remove the scratch screen message.
(setq initial-scratch-message "")

;; ===================
;; Disable various file and UI features
;; ===================
;; Disable backup files
(setq make-backup-files nil)

;; Disable auto-save files
(setq auto-save-default nil)

;; Disable lockfiles (those prefixed with `.#`)
(setq create-lockfiles nil)

;; Disable the toolbar
(tool-bar-mode -1)

;; Disable the menu bar
(menu-bar-mode -1)

;; Disable the scroll bar
(scroll-bar-mode -1)

(setq inhibit-splash-screen t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      inhibit-startup-buffer-menu t
      use-file-dialog nil
      use-short-answers t)

;; ===================
;; Enable pixel-scroll precision mode
;; ===================
(use-package emacs
  :init
  (pixel-scroll-precision-mode 1))

;; ===================
;; Additional UI settings
;; ===================
(setq ring-bell-function 'ignore)  ;; Disable the bell sound
(setq visible-bell nil)  ;; Disable visual bell

;; ===================
;; Optimize file handling on startup
;; ===================
;; Disable file name handlers for faster startup.
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist (default-value 'file-name-handler-alist))))

;; Prevent package.el from auto-loading
(setq package-enable-at-startup nil)

(provide 'early-init)
