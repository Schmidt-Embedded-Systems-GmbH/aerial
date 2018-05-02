FROM ocaml/opam:ubuntu-14.04_ocaml-4.04.1

RUN opam install \
    ocamlfind \ 
    menhir \ 
    safa
USER opam
ENV WDIR /home/opam/aerial
RUN mkdir -p ${WDIR}
WORKDIR ${WDIR}
ADD . ${WDIR}
RUN eval `opam config env` && make && sudo cp aerial.native /usr/local/bin/aerial
