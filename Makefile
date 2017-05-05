NAME=src/aerial
OCAMLBUILD=ocamlbuild -use-ocamlfind -no-plugin -yaccflag --explain
OCAMLBUILDWEB=ocamlbuild -use-ocamlfind \
           -plugin-tags "package(js_of_ocaml.ocamlbuild)" -package yojson -yaccflag --explain
OCAMLFIND=ocamlfind
OBJS=$(wildcard _build/*.cm* _build/*.a _build/*.o)
# OBJS=$(wildcard _build/*.{cmi,cmo,cma,cmx,cmxa,a,o})

SOURCEFOLDER=src
TESTNAME=qtest
TESTBUILD=_buildtest
TESTFOLDER=test
TESTPATH=$(TESTBUILD)/$(TESTNAME)
OCAMLBUILDTEST=ocamlbuild -cflags -warn-error,+26 -use-ocamlfind -use-menhir \
			   -plugin-tags "package(js_of_ocaml.ocamlbuild)"  -yaccflag --explain \
			   -pkgs qcheck -Is $(SOURCEFOLDER)/,$(TESTFOLDER)/ 

ifndef PREFIX
  PREFIX=/usr/local
else
  PREFIX:=${PREFIX}
endif

standalone:
	$(OCAMLBUILD) $(NAME).native

install: 
	cp ./aerial.native $(PREFIX)/bin/aerial

uninstall:
	rm -f ${PREFIX}/bin/aerial

test-generate:
	mkdir -p $(TESTBUILD)
	qtest -o $(TESTPATH).ml extract $(TESTFOLDER)/*.ml

test-compile: test-generate
	$(OCAMLBUILDTEST) $(TESTPATH).native
	mv $(TESTNAME).native $(TESTBUILD)/
	mv $(TESTNAME).targets.log $(TESTBUILD)/

test-clean: 
	rm -rf $(TESTBUILD)

test: test-clean test-generate test-compile
	./$(TESTPATH).native

lib:
	$(OCAMLBUILD) $(NAME).cmxa
	$(OCAMLBUILD) 
doc:
	$(OCAMLBUILD) $(NAME).docdir/index.html

clean:
	rm -f applet/aerial.js
	$(OCAMLBUILD) -clean

clean-all: clean test-clean

bc-standalone:
	$(OCAMLBUILD) $(NAME).byte

bc-lib:
	$(OCAMLBUILD) $(NAME).cma

nc-lib:
	$(OCAMLBUILD) $(NAME).cmxa

web:
	$(OCAMLBUILDWEB) -I src applet/applet.byte
	js_of_ocaml -I . --file examples:/ applet.byte -o applet/aerial.js

run:
	$(OCAMLBUILD) $(NAME).native
	./aerial.native $(CMD)