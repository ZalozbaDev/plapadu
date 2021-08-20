#!/bin/bash

mkdir -p /exchange/output/tmp/
rm -f /exchange/output/tmp/*

perl hsb-tts.pl --tex hyph-hsb.tex --infile /exchange/input/text.txt --outfile /plapadu1.txt --mute

cp /plapadu1.txt /exchange/output/tmp/

sed -i "s/ł/w/g" /plapadu1.txt
sed -i "s/ć/cz/g" /plapadu1.txt
sed -i "s/–/-/g" /plapadu1.txt
sed -i 's/„/"/g' /plapadu1.txt
sed -i 's/“/"/g' /plapadu1.txt
# soft hyphen :-( 
sed -i 's/\xC2\xAD//g' /plapadu1.txt
# whatever this is
sed -i 's/\x82//g' /plapadu1.txt

iconv -f UTF8 -t ISO8859-2 /plapadu1.txt > /festinput.txt

cp /festinput.txt /exchange/output/tmp/

rm -f /exchange/output/speech.*

festival -b festival_command.txt

sox -r 16000 -e signed-integer -b 16 -c 1 -t raw /exchange/output/speech.raw /exchange/output/speech.wav tempo 0.7 pitch -100
