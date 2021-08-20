FROM debian:buster-slim
MAINTAINER Daniel Sobe <daniel.sobe@sorben.com>

# docker build -t plapadu_oss .
# docker build -t plapadu_oss . --no-cache

RUN sed -i "s/main/main contrib non-free/g" /etc/apt/sources.list && cat /etc/apt/sources.list

RUN apt update

RUN apt install -y cpanminus sox festival mbrola wget

# download more resources

RUN wget http://mirror.ctan.org/language/hyph-utf8/tex/generic/hyph-utf8/patterns/tex/hyph-hsb.tex

RUN wget http://festvox.org/voices/polish/pjwstk_ks_multisyn_mbrola.tar.bz2

RUN apt install -y make

RUN cpan Number::Convert::Roman

RUN cpan TeX::Hyphen

RUN apt install -y nano locales bzip2

RUN mkdir -p /tmp/voice_pl/ && tar xvfj pjwstk_ks_multisyn_mbrola.tar.bz2 -C /tmp/voice_pl/

RUN cp -r /tmp/voice_pl/lib/voices/polish /usr/share/festival/voices/

RUN mkdir -p /exchange/input/
RUN mkdir -p /exchange/output/

RUN sed -i -e 's/# pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen && \
	sed -i -e 's/# pl_PL ISO-8859-2/pl_PL ISO-8859-2/' /etc/locale.gen && \
    locale-gen

COPY hsb-tts.pl patterns.tts plapadu_hsb.sh festival_command.txt /

ENV LC_ALL pl_PL.UTF-8 
ENV LANG pl_PL.UTF-8  

# to run container:
## mkdir -p input && mkdir -p output 
## docker run --mount type=bind,source="$(pwd)"/input,target=/exchange/input/ --mount type=bind,source="$(pwd)"/output,target=/exchange/output/ -it plapadu_oss /plapadu_hsb.sh

# debugging:
## docker run --mount type=bind,source="$(pwd)"/input,target=/exchange/input/ --mount type=bind,source="$(pwd)"/output,target=/exchange/output/ -it plapadu_oss /bin/bash
