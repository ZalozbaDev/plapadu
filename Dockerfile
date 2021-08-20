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

# to run container:
## docker run --privileged -it plapadu_oss /bin/bash
