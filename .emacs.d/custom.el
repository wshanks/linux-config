;;; custom -- Summary
;;; Commentary:
;;; Code:
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("8db4b03b9ae654d4a57804286eb3e332725c84d7cdab38463cb6b97d5762ad26" default)))
 '(display-buffer-function (quote popwin:display-buffer))
 '(package-selected-packages
   (quote
    (modeline-posn popup rainbow-delimiters fill-column-indicator color-theme-solarized popwin key-chord general fzf frame-fns flycheck evil-org evil-magit auctex ag use-package wc-mode elisp-slime-nav))))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(tool-bar ((t (:background "dim gray" :foreground "light gray" :box (:line-width 1 :style released-button))))))

(provide 'custom)
;;; custom ends here
