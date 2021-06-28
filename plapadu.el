;;; elisp interface for the plapadu tts system
;;; Eduard Werner, 2020

(defun plapadu-start ()
  "Startuje plapadu tts-system."
  (interactive)
					;(start-process "plapadu" "plapadu-output" "/usr/local/bin/perl" "/Users/edi/Documents/Projekty/tts/dsb-tts.pl" "--tts" "/Users/edi/Documents/Projekty/tts/patterns.tts" "--tex" "/Users/edi/Documents/Projekty/tts/hyph-pl.tex" )
  (start-process  "plapadu" "plapadu-output" "/usr/local/bin/perl" "/Users/edi/Documents/Projekty/tts/plapadu.pl")
  (process-send-string (get-process "plapadu") "Plapadu je wotućił.\n"))

(defun plapadu-restart ()
  "Startuje plapadu tts system znowa."
  (interactive)
  (plapadu-stop)
  (plapadu-start))

(defun plapadu-stop ()
  "Zastaji plapadu tts system."
  (interactive)
  (delete-process (get-process "plapadu")))

(defun plapadu-check-process ()
  "Startuje plapadu tts system, jeli trěbne."
  (interactive)
  (if (not (get-process "plapadu"))
      (plapadu-start)))

(defun plapadu-read-current-word ()
  "Čita słowo pod kursorom."
  (interactive)
  (plapadu-check-process)
  (message "%s" (thing-at-point 'word))
  (process-send-string "plapadu" (thing-at-point 'word))
  (process-send-string "plapadu" "\n"))

(defun plapadu-cytaj () ; reads region if active and current par otherwise
    "Čita markěrowany tekst abo wotrězk pod kursorom."
  (interactive)
  (if (and transient-mark-mode mark-active) ; if region is active
      (plapadu-read-region)
    (plapadu-read-current-par)))

(defun plapadu-read-current-par ()
  "Čita wotrězk pod kursorom."
  (interactive)
  (plapadu-check-process)
  (process-send-string (get-process "plapadu") ; replacing all the newlines is vital for plapadu.pl to catch balanced expresssions,
					; the parens and so on have to be replaced because it breaks the echo command
					; needs sth else though so we don't lose the structure, but brackets seem to work
		       (replace-regexp-in-string "[\(\<\`]" "["
						 (replace-regexp-in-string "[\)\>]" "]"
						 (replace-regexp-in-string "\n" " " (buffer-substring-no-properties (re-search-backward "\n\n+" nil 'xx) (re-search-forward "\n\n+" nil t 2))))))
   (process-send-string  (get-process "plapadu") "\n"))


(defun plapadu-read-region ()
  "Read out region."
  (interactive)
  (plapadu-check-process)
  ; (message "%s" (replace-regexp-in-string "\n" " " (buffer-substring-no-properties (region-beginning) (region-end))))
  (process-send-string  (get-process "plapadu")
			(replace-regexp-in-string "[\(\<\`]" "["
						  (replace-regexp-in-string "[\)\>]" "]"
									    "" (replace-regexp-in-string "\n" " " (buffer-substring-no-properties (region-beginning) (region-end))))))
  (process-send-string "plapadu" "\n"))



;; this will be done properly according to the LaTeX stuff
;;(tool-bar-add-item "plapadu-icon" 'plapadu-cytaj
;;               'plapadu-cytaj
;;               :help   "cytaj serbski tekst")
