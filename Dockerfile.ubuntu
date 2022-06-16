FROM ocaml/opam2:ubuntu-18.04

RUN sudo apt-get update \
    && sudo apt-get install -y \
    subversion \
    m4 \
    libgmp-dev \
    && sudo rm -rf /var/lib/apt/lists/* 

# RUN opam init -y \
RUN opam update \
    && opam switch create 4.06.1
RUN opam install \
       ocamlfind \
       menhir \
       safa \
       qcheck

USER opam
ENV WDIR /home/opam/aerial
RUN mkdir -p ${WDIR}
WORKDIR ${WDIR}
ADD . ${WDIR}
RUN eval `opam config env` \
      && make && sudo make generate \
      && sudo cp aerial.native /usr/local/bin/aerial \
      && sudo cp generator_main.native /usr/local/bin/gen_fmla
