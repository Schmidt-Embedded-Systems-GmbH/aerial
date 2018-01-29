FROM ocaml/ocaml:ubuntu-14.04

RUN add-apt-repository ppa:avsm/ppa
RUN apt-get update && apt-get install -y opam git wget
RUN opam init
RUN opam update
RUN opam switch 4.04.1
RUN opam install ocamlfind
RUN opam install menhir
RUN opam install safa

ENV WDIR /home/root/aerial
RUN mkdir -p ${WDIR}
WORKDIR ${WDIR}
ADD . ${WDIR}
#RUN echo "$(opam config env)" >> /etc/profile
RUN eval `opam config env` && make
RUN eval `opam config env` && make install
