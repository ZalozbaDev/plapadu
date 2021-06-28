# plapadu
multilingual tts system frontend and tts system for Upper and Lower Sorbian

This has been used on Mac OS only. The tts system requires:
- a Polish voice and tts system (like Ewa on Mac OS)
- working Perl environment
- spelling checks for all the languages you want to check or might encounter in your texts (from libreOffice)
- hyphenation files (from .tex)
- lots of patience for the setup (make sure you have your favourite curses at the ready, just in case)

1. edit plapadu.pl and adjust the paths, file names etc. This is the main file for multilingual texts.
2. edit patterns.tts for your personal needs
3. hsb-tts.pl and dsb-tts.pl are the preprocessors to feed Upper Sorbian or Lower Sorbian to a Polish tts.
4. plapadu.el a QD shot at an emacs interface (works with my Aquamacs)

Depending on your tts system for Polish, you might need workarounds. Numbers and digits should be working.
