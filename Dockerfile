FROM ocaml/opam:alpine-3.14-ocaml-4.06-flambda AS build


RUN sudo apk add --no-cache \
    subversion \
    m4 \
    gmp-dev \
    && opam update

# RUN opam init -y \
RUN opam install \
       ocamlfind \
       menhir \
       safa \
       qcheck

COPY --chown=opam:opam . build
WORKDIR build

ADD . build
RUN eval `opam config env` \
      && make \
      && sudo cp aerial.native /usr/local/bin/aerial 

FROM alpine:3.14

RUN apk add --no-cache gmp

COPY --from=build /usr/local/bin/aerial /usr/local/bin

ENV WDIR /work
WORKDIR $WDIR
ENTRYPOINT ["aerial", "-flush"]
