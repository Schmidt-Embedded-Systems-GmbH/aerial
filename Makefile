NAME=src/aerial
OCAMLBUILD=ocamlbuild -use-ocamlfind -use-menhir -pkg hashcons \
           -plugin-tags "package(js_of_ocaml.ocamlbuild)" -yaccflag --explain
OCAMLFIND=ocamlfind
OBJS=$(wildcard _build/*.cm* _build/*.a _build/*.o)
# OBJS=$(wildcard _build/*.{cmi,cmo,cma,cmx,cmxa,a,o})

ifndef PREFIX
  PREFIX=/usr/local
else
  PREFIX:=${PREFIX}
endif

standalone:
	$(OCAMLBUILD) $(NAME).native

install: bc-lib nc-lib standalone
	@$(OCAMLFIND) install $(NAME) META $(OBJS)
	install $(NAME).native $(PREFIX)/bin/$(NAME)

uninstall:
	$(OCAMLFIND) remove $(NAME)
	rm -f ${PREFIX}/bin/$(NAME)

lib:
	$(OCAMLBUILD) $(NAME).cmxa

doc:
	$(OCAMLBUILD) $(NAME).docdir/index.html

clean:
	rm -f applet/aerial.js
	$(OCAMLBUILD) -clean

bc-standalone:
	$(OCAMLBUILD) $(NAME).byte

bc-lib:
	$(OCAMLBUILD) $(NAME).cma

nc-lib:
	$(OCAMLBUILD) $(NAME).cmxa

web:
	$(OCAMLBUILD) -package yojson -I src applet/applet.byte
	js_of_ocaml -I . --file examples:/ applet.byte -o applet/aerial.js

run:
	$(OCAMLBUILD) $(NAME).native
	./aerial.native $(CMD)