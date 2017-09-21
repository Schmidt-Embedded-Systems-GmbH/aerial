EXENAME=aerial
MODULENAME=main
NAME=src/$(MODULENAME)
OCAMLBUILD=ocamlbuild -use-ocamlfind -no-plugin -package safa -yaccflags --explain
OCAMLBUILDWEB=ocamlbuild -use-ocamlfind \
	       -plugin-tags "package(js_of_ocaml.ocamlbuild)" -package yojson \
           -package safa -yaccflag --explain
OCAMLFIND=ocamlfind
OBJS=$(wildcard _build/*.cm* _build/*.a _build/*.o)
# OBJS=$(wildcard _build/*.{cmi,cmo,cma,cmx,cmxa,a,o})

SOURCEFOLDER=src
TESTNAME=qtest
TESTBUILD=_buildtest
TESTFOLDER=test
TESTPATH=$(TESTBUILD)/$(TESTNAME)
OCAMLBUILDTEST=ocamlbuild -cflags -warn-error,+26 -use-ocamlfind  \
			   -no-plugin -package safa -yaccflag --explain \
			   -pkgs qcheck -Is $(SOURCEFOLDER)/,$(TESTFOLDER)/
OCAMLBUILDCOVERAGE=ocamlbuild -cflags -warn-error,+26 -use-ocamlfind  \
			   -no-plugin -package safa -yaccflag --explain \
			   -pkgs bisect_ppx,qcheck -Is $(SOURCEFOLDER)/,$(TESTFOLDER)/

OCAMLBUILDGEN=$(OCAMLBUILD) -pkgs qcheck
GENNAME=src/generator_main
GENMONPOLY=experiments/gen_log

IMAGE=krledmno1/aerial

ifndef PREFIX
  PREFIX=/usr/local
else
  PREFIX:=${PREFIX}
endif

standalone:
	$(OCAMLBUILD) $(NAME).native
	mv -f $(MODULENAME).native $(EXENAME).native

install: standalone
	cp ./$(EXENAME).native $(PREFIX)/bin/$(EXENAME)

uninstall:
	rm -f ${PREFIX}/bin/$(EXENAME)

test-generate:
	mkdir -p $(TESTBUILD)
	qtest -o $(TESTPATH).ml extract $(TESTFOLDER)/*_test.ml

test-compile: test-generate
	$(OCAMLBUILDTEST) $(TESTPATH).native
	mv $(TESTNAME).native $(TESTBUILD)/
	mv $(TESTNAME).targets.log $(TESTBUILD)/

test-clean:
	rm -rf $(TESTBUILD)

test: test-clean test-generate test-compile
	./$(TESTPATH).native

generate:
	$(OCAMLBUILDGEN) $(GENNAME).native
	cp generator_main.native experiments/
	cp generator_main.native integration/

generate-monpoly:
	$(OCAMLBUILD) $(GENMONPOLY).native
	cp gen_log.native experiments/

lib:
	$(OCAMLBUILD) $(NAME).cmxa
	$(OCAMLBUILD)
doc:
	$(OCAMLBUILD) $(NAME).docdir/index.html

clean:
	rm -f applet/aerial.js
	$(OCAMLBUILD) -clean

clean-all: clean test-clean clean-performance clean-coverage

bc-standalone:
	$(OCAMLBUILD) $(NAME).byte

bc-lib:
	$(OCAMLBUILD) $(NAME).cma

nc-lib:
	$(OCAMLBUILD) $(NAME).cmxa

web:
	$(OCAMLBUILDWEB) -I src applet/applet.byte
	js_of_ocaml -I . --file examples:/ applet.byte -o applet/aerial.js

run: standalone
	./aerial.native $(CMD)

docker:
	docker build -t $(IMAGE) .

docker-push: docker
	docker login
	docker push $(IMAGE)

coverage: test-clean test-generate
	$(OCAMLBUILDCOVERAGE) $(TESTPATH).native
	mv $(TESTNAME).native $(TESTBUILD)/
	mv $(TESTNAME).targets.log $(TESTBUILD)/
	cd _build; ../$(TESTPATH).native
	bisect-ppx-report -I _build/ -html _build/coverage/ _build/bisect*.out
	open _build/coverage/index.html

clean-coverage:
	rm -rf _build/bisect*.out
	rm -r _build/coverage

# set the value in maxidx to less then 5 (with 3 it takes about a minute)
performance: install
	test -f ./integration/db.csv || (echo Database file does not exist, run make performance-db first; exit -1)
	(cd ./integration; ./performance_test.sh mtl 0.05)

# set the value in maxidx to roughly 20 or more (takes about 2 hours)
performance-db: install
	(cd ./integration; ./performance_test.sh mtl 0.25 db 2> /dev/null)
	mv ./integration/results-avg.csv ./integration/db.csv

clean-performance:
	rm ./integration/generator_main.native
	rm ./integration/results*

