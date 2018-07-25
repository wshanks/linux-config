;; Always use same desktop file. There should be only one daemon
(setq desktop-load-locked-desktop t)
;; save the desktop file automatically if it already exists
(setq desktop-save 'if-exists)
(desktop-save-mode t)
(desktop-change-dir "~/.emacs.d")
