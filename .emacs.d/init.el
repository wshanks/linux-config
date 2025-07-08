;;; init -- Summary
;;; Commentary:
;;; Code:
;; Save history
(savehist-mode t)

;; General display
(visual-line-mode t)
;; (add-hook 'text-mode-hook 'turn-on-visual-line-mode)
(global-display-line-numbers-mode t)
(column-number-mode t)
(show-paren-mode t)
(setq ring-bell-function 'ignore)
(setq inhibit-splash-screen t)
(setq frame-background-mode 'dark)
;; Hide menu in terminal
(defun contextual-menubar (&optional frame)
  "Hide menu bar in tty"
  (interactive)
  (set-frame-parameter frame 'menu-bar-lines
                             (if (display-graphic-p frame)
                                  1 0)))
(add-hook 'after-make-frame-functions 'contextual-menubar)
(add-hook 'after-init-hook 'contextual-menubar)
(set-face-attribute 'tool-bar nil
                    :background "dim gray"
                    :foreground "light gray")

(setq-default custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))
(fset 'yes-or-no-p 'y-or-n-p)
(setq-default indent-tabs-mode nil)
(global-auto-revert-mode t)
(recentf-mode 1)
(setq recentf-max-saved-items 200)

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)


;; Buffers
(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(ido-mode 1)
(global-set-key (kbd "C-x C-b") 'ibuffer)
(setq ibuffer-expert t)
(setq read-file-name-completion-ignore-case 1)
(setq read-buffer-completion-ignore-case 1)

;; Clipboard
(setq select-enable-clipboard t)
;; (setq interprogram-paste-function 'x-cut-buffer-or-selection-value)

;; Org mode
;;
(defun org-summary-todo (n-done n-not-done)
       "Switch entry to DONE when all subentries are done, to TODO otherwise."
       (let (org-log-done org-log-states)   ; turn off logging
         (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
     (add-hook 'org-after-todo-statistics-hook 'org-summary-todo)
;; Workaround for org-mode problem with gnome terminal
;; https://gist.github.com/hanachin/997420
(add-hook 'org-mode-hook
      (lambda ()
        (if window-system
            nil
          (progn
            (define-key org-mode-map "\C-\M-j" 'org-meta-return)
            (define-key org-mode-map "\C-j" 'org-insert-heading-respect-content)))))
(defun nolinum ()
  (linum-mode 0)
)
(add-hook 'org-mode-hook 'nolinum)


;; External packages
;;
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list
 'package-archives
 '("melpa" . "https://melpa.org/packages/")
 t)
(package-initialize)

;; Install non-distributed package
(unless (package-installed-p 'frame-fns)
  (require 'url)
  (url-copy-file "https://raw.githubusercontent.com/wshanks/frame-fns/master/frame-fns.el" "/tmp/frame-fns.el" t)
  (package-install-file "/tmp/frame-fns.el"))

;; Install non-distributed package
(unless (package-installed-p 'modeline-posn)
  (require 'url)
  (url-copy-file "https://raw.githubusercontent.com/wshanks/modeline-posn/master/modeline-posn.el" "/tmp/modeline-posn.el" t)
  (package-install-file "/tmp/modeline-posn.el"))

(unless (package-installed-p 'use-package)
   (package-refresh-contents)
   (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
;; (require 'bind-key)                ;; if you use any :bind variant
(setq use-package-always-ensure t)

(use-package flycheck
  :config
  (global-flycheck-mode)
  (setq flycheck-check-syntax-automatically '(mode-enabled save idle-change))
  (setq flycheck-idle-change-delay 10))

(use-package diminish
  :config
  (eval-after-load "hideshow" '(diminish 'hs-minor-mode))
  (eval-after-load "undo-tree" '(diminish 'undo-tree-mode))
  (eval-after-load "simple" '(diminish 'overwrite-mode))
  (eval-after-load "autorevert" '(diminish 'auto-revert-mode)))


;; (use-package key-chord
;;   :init
;;   (progn
;;     (key-chord-mode 1)
;;     (setq key-chord-two-keys-delay 0.4)))

(use-package minimal-session-saver
  :config
  (minimal-session-saver-load))

(use-package popwin
  :config
  (popwin-mode t)
  (customize-set-variable 'display-buffer-function (quote popwin:display-buffer)))

(use-package magit
  :commands (magit-status
             magit-diff
             magit-commit
             magit-log
             magit-push
             magit-stage-file
             magit-unstage-file))

(use-package general
    :config
    (setq general-default-prefix "SPC")
    (general-define-key :prefix "g"
			:states '(visual)
			"c" 'comment-dwim)
    (general-define-key :prefix "g"
			:states '(normal)
			"c" 'comment-line)
    (general-define-key :prefix "g"
			:states '(normal)
			"b" 'mode-line-other-buffer)
    (general-define-key :states '(normal)
			"b" 'ibuffer)
    (general-define-key :states '(normal)
			"s" 'switch-to-buffer)
    (use-package org
      :config
      (progn
	(general-define-key :keymaps 'org-mode-map
			    :states '(normal)
			    "t" 'org-todo)
	(general-define-key :prefix "g"
			    :states '(normal)
			    :keymaps 'org-mode-map
			    "u" 'org-up-element
			    "d" 'org-down-element
			    "h" 'org-backward-element
			    "l" 'org-forward-element))))

(use-package evil
  :init
  (setq evil-want-C-u-scroll t)
  (setq evil-want-keybinding nil)
  (setq evil-toggle-key "C-`")
  (setq evil-undo-system 'undo-redo)
  :bind (:map evil-normal-state-map
              ("zz" . suspend-frame)
              ("C-j" . evil-window-down)
              ("C-k" . evil-window-up)
              ("C-h" . evil-window-left)
              ("C-l" . evil-window-right))
  :config
  (evil-mode 1)
  (evil-set-initial-state 'term-mode 'emacs)  ;; Needed for fzf
  (add-hook 'term-mode-hook 'evil-emacs-state)
  (evil-add-hjkl-bindings package-menu-mode-map 'emacs
  "H" 'package-menu-quick-help
  "/" 'evil-search-forward
  "n" 'evil-search-next
  "N" 'evil-search-previous
  )
  (define-key evil-normal-state-map "\C-n" nil)
  (define-key evil-normal-state-map "\C-p" nil)
  ;; Faster escape sequence
  ;; (use-package key-chord
  ;;   :config
  ;;   ;; This isn't enough to escape from company-mode completion
  ;;   (key-chord-define evil-insert-state-map "kj" 'evil-normal-state))
  (use-package evil-escape
    :config
    (setq-default evil-escape-key-sequence "kj")
    (setq-default evil-escape-delay 0.4)
    (evil-escape-mode t))
  ;; LaTeX
  (eval-after-load 'latex
    '(define-key evil-normal-state-map (kbd "j")
       'evil-next-visual-line))
  (eval-after-load 'latex
    '(define-key evil-normal-state-map (kbd "k")
       'evil-previous-visual-line))

  (defun my-dired-up-directory ()
    "Take dired up one directory, but behave like dired-find-alternate-file"
    (interactive)
    (let ((old (current-buffer)))
      (dired-up-directory)
      (kill-buffer old)))
  (eval-after-load 'dired
    '(progn
      (evil-set-initial-state 'dired-mode 'normal)
      (evil-define-key 'normal dired-mode-map "h" 'my-dired-up-directory)
      (evil-define-key 'normal dired-mode-map "l" 'dired-find-alternate-file)
      (evil-define-key 'normal dired-mode-map "o" 'dired-sort-toggle-or-edit)
      (evil-define-key 'normal dired-mode-map "v" 'dired-toggle-marks)
      (evil-define-key 'normal dired-mode-map "m" 'dired-mark)
      (evil-define-key 'normal dired-mode-map "u" 'dired-unmark)
      (evil-define-key 'normal dired-mode-map "U" 'dired-unmark-all-marks)
      (evil-define-key 'normal dired-mode-map "c" 'dired-create-directory)
      (evil-define-key 'normal dired-mode-map "n" 'evil-search-next)
      (evil-define-key 'normal dired-mode-map "N" 'evil-search-previous)
      (evil-define-key 'normal dired-mode-map "q" 'kill-this-buffer)))

  (use-package org
    :config
    (evil-define-key 'normal org-mode-map (kbd "TAB") #'org-cycle)
    ; org bindings
    (evil-define-key 'normal org-mode-map
      (kbd "M-h") 'org-shiftmetaleft
      (kbd "M-j") 'org-shiftmetadown
      (kbd "M-k") 'org-shiftmetaup
      (kbd "M-l") 'org-shiftmetaright)
    (use-package evil-org
      ;; evil-org:
      ;;  base: o open below, O open above
      ;;  heading: O insert heading, M-o insert subheading
      :config
      (add-hook 'org-mode-hook 'evil-org-mode)
      (evil-org-set-key-theme '(heading))
      ;; Undo evil-org 0,$ mappings
      (evil-define-key 'motion evil-org-mode-map
                       (kbd "0") 'evil-beginning-of-line)
      (evil-define-key 'motion evil-org-mode-map
                       (kbd "$") 'evil-end-of-line)))
   (use-package general
     :config
     (general-define-key :prefix "g"
                         :states '(normal)
                         :keymaps 'org-mode-map
                         "U" 'evil-org-top)
     (general-define-key :keymaps 'org-mode-map
                         :states '(normal)
                         "l" 'evil-org-open-links))
   (use-package magit
     :config
     (evil-set-initial-state 'magit-mode 'normal)
     (evil-set-initial-state 'magit-status-mode 'normal)
     (evil-set-initial-state 'magit-diff-mode 'normal)
     (evil-set-initial-state 'magit-log-mode 'normal)
     (evil-define-key 'normal magit-mode-map
         "j" 'magit-goto-next-section
         "k" 'magit-goto-previous-section)
     (evil-define-key 'normal magit-log-mode-map
         "j" 'magit-goto-next-section
         "k" 'magit-goto-previous-section)
     (evil-define-key 'normal magit-diff-mode-map
         "j" 'magit-goto-next-section
         "k" 'magit-goto-previous-section)))

(use-package ag
    :config
    (progn
	(setq compilation-scroll-output 'first-error)
	(setq ag-reuse-window t)
	(setq ag-reuse-buffers t)
	(add-hook 'ag-search-finished-hook
		  (lambda () (pop-to-buffer next-error-last-buffer)))
	(use-package general
	  :config
          (general-define-key :states '(normal)
                              "a" 'ag-project)
	  )))

(use-package fzf
  :config
  (use-package general
    :config
    (general-define-key :states '(normal)
			"f" 'fzf-git)))

(use-package magit
  :config
  (use-package evil
    :config
    (use-package evil-collection
      :config
      (evil-collection-init 'ibuffer)
      (evil-collection-magit-setup)
      (use-package general
	:config
        (general-define-key :states '(normal)
                            "g" 'magit-status)))))

(use-package company
  :config
  (company-tng-configure-default)
  (add-hook 'emacs-lisp-mode-hook 'company-mode)
  (use-package ycmd
    :init
    (setq ycmd-startup-timeout 10)
    :config
    (set-variable 'ycmd-server-command
                  `("/usr/bin/python"
                    ,(file-truename "~/.vim/plugged/YouCompleteMe/third_party/ycmd/ycmd")))
    (set-variable 'ycmd-python-binary-path "python")
    (add-hook 'python-mode-hook 'ycmd-mode)
    (add-hook 'python-mode-hook 'ycmd-eldoc-setup)
    (use-package company-ycmd
      :config
      (company-ycmd-setup))
    (add-hook 'python-mode-hook 'company-mode)
    (use-package general
        :config
        ;; Show doc
        (general-define-key :keymaps 'python-mode-map
                            :states '(normal)
                            "d" 'ycmd-show-documentation)
        ;; Go to
        (general-define-key :keymaps 'python-mode-map
                            :states '(normal)
                            "j" 'ycmd-goto)))
  (use-package fill-column-indicator
    :config
    (defun on-off-fci-before-company(command)
      (when (string= "show" command)
        (turn-off-fci-mode))
      (when (string= "hide" command)
        (turn-on-fci-mode))))
    (advice-add 'company-call-frontends :before #'on-off-fci-before-company))


  ;; (use-package company-jedi
  ;;   :config
  ;;   (add-to-list 'company-backends 'company-jedi)
  ;;   (add-hook 'python-mode-hook 'company-mode)))


;; (use-package jedi
;;   :config
;;   (ac-linum-workaround)
;;   (add-hook 'python-mode-hook 'jedi:setup)
;;   (add-hook 'python-mode-hook
;;             (lambda () (progn (add-to-list 'ac-sources 'ac-source-words-in-buffer)
;;                               (delete 'ac-source-words-in-same-mode-buffers
;;                                       ac-sources))))
;;   (setq jedi:complete-on-dot t)
;;   (setq jedi:tooltip-method nil)
;;   (setq jedi:get-in-function-call-delay 2000)
;;   (setq ac-use-menu-map t)
;;   (define-key ac-menu-map (kbd "S-TAB") 'ac-expand-previous)
;;   (define-key ac-menu-map (kbd "<backtab>") 'ac-expand-previous)
;;   (define-key ac-menu-map (kbd "C-g") 'ac-stop)
;;   (setq ac-auto-show-menu t)
;;   (use-package general
;;     :config
;;     ;; Show doc, also C-c ?
;;     (general-define-key :keymaps 'python-mode-map
;;                         :states '(normal)
;;  		        "d" 'jedi:show-doc)
;;     ;; Go to def, also C-c .
;;     (general-define-key :keymaps 'python-mode-map
;;                         :states '(normal)
;;  		        "j" 'jedi:goto-definition)
;;     ;; Go back from def, also C-c ,
;;     (general-define-key :keymaps 'python-mode-map
;;                         :states '(normal)
;;  		        "k" 'jedi:goto-definition-pop-marker))
;;   (use-package popwin
;;     :config
;;     (push '("*jedi:doc*") popwin:special-display-config)))

(use-package elisp-slime-nav
  :config
  (defun my-lisp-hook ()
    (elisp-slime-nav-mode)
    (eldoc-mode))
  (add-hook 'emacs-lisp-mode-hook 'my-lisp-hook)
  (use-package evil
    :config
    (evil-define-key 'normal emacs-lisp-mode-map (kbd "K")
      'elisp-slime-nav-describe-elisp-thing-at-point)))

(use-package wc-mode)

;; Theming
 (use-package solarized-theme
   :config
   (load-theme 'solarized-wombat-dark t))

(use-package frame-fns
  :config
  (defun set-selected-frame-dark ()
    "Select dark theme for GUI windows."
    (interactive)
    (let ((frame-name (get-frame-name (selected-frame))))
      (call-process-shell-command (concat "xprop -f _GTK_THEME_VARIANT 8u -set _GTK_THEME_VARIANT \"dark\" -name \""
                                          frame-name
                                          "\""))))
  (if (window-system)
      (set-selected-frame-dark)))

(use-package modeline-posn
  :config
  (setq modelinepos-column-limit 80))

(use-package fill-column-indicator
  :config
  (setq fci-rule-column 80)
  (add-hook 'python-mode-hook 'fci-mode))
  ;; (defvar my-fci-mode-suppressed nil)
  ;; (defadvice popup-create (before suppress-fci-mode activate)
  ;;   "Suspend fci-mode while popups are visible"
  ;;   (set (make-local-variable 'my-fci-mode-suppressed) fci-mode)
  ;;   (when fci-mode (turn-off-fci-mode)))
  ;; (defadvice popup-delete (after restore-fci-mode activate)
  ;;   "Restore fci-mode when all popups have closed"
  ;;   (when (and (not popup-instances) my-fci-mode-suppressed)
  ;;   (setq my-fci-mode-suppressed nil)
    ;; (turn-on-fci-mode))))

(use-package rainbow-delimiters
    :commands (rainbow-delimiters-mode)
    :init
    (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))


;; LaTeX stuff
(setenv "TEXMFDIST" "$HOME/root/stow/texlive/texmf-dist")
(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
(customize-set-variable 'preview-scale-function 1.5)

(provide 'init)
;;; init.el ends here
