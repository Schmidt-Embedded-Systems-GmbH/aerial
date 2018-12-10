#!/bin/bash

source ./functions.sh

# logs=$1 # random local
# type=$2

mkdir -p figures
now=$($DATE +"%Y_%m_%d-%H-%M")

#./results/now
path=$1

#EXPERIMENTS="rates formulas intervals"
EXPERIMENTS="rates formulas intervals"

for ex in $EXPERIMENTS; do

    #NAIVE vs LOCAL vs GLOBAL

    # #NAIVE vs LOCAL vs GLOBAL (with fixed expr, MDL)
    # sed "s/MODS/aerial-mdl-naive-expr, aerial-mdl-local-expr, aerial-mdl-global-expr/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-mode-mdl-expr-$now.tex
    # latexmk -shell-escape -pdf ${ex}-mode-mdl-expr-$now.tex

    # #NAIVE vs LOCAL vs GLOBAL (with fixed expr, MTL)
    # sed "s/MODS/aerial-mtl-naive-expr, aerial-mtl-local-expr, aerial-mtl-global-expr/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-mode-mtl-expr-$now.tex
    # latexmk -shell-escape -pdf ${ex}-mode-mtl-expr-$now.tex
    
    # #NAIVE vs LOCAL vs GLOBAL (with fixed safa, MDL)
    # sed "s/MODS/aerial-mdl-naive-safa, aerial-mdl-local-safa, aerial-mdl-global-safa/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-mode-mdl-safa-$now.tex
    # latexmk -shell-escape -pdf ${ex}-mode-mdl-safa-$now.tex

    # #LOCAL vs GLOBAL (with fixed expr, MDL)
    # sed "s/MODS/aerial-mdl-local-expr, aerial-mdl-global-expr/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-mode-mdl-expr-LG-$now.tex
    # latexmk -shell-escape -pdf ${ex}-mode-mdl-expr-LG-$now.tex
    
    # #NAIVE vs LOCAL vs GLOBAL (with fixed safa, MDL)
    # sed "s/MODS/aerial-mdl-local-safa, aerial-mdl-global-safa/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-mode-mdl-safa-LG-$now.tex
    # latexmk -shell-escape -pdf ${ex}-mode-mdl-safa-LG-$now.tex


    # #expr vs bdd vs safa

    # #expr vs bdd vs safa (with fixed global, MDL)
    # sed "s/MODS/aerial-mdl-global-expr, aerial-mdl-global-bdd, aerial-mdl-global-safa/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-repr-mdl-global-$now.tex
    # latexmk -shell-escape -pdf ${ex}-repr-mdl-global-$now.tex

    # #expr vs bdd vs safa (with fixed naive, MDL)
    # sed "s/MODS/aerial-mdl-naive-expr, aerial-mdl-naive-bdd, aerial-mdl-naive-safa/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-repr-mdl-naive-$now.tex
    # latexmk -shell-escape -pdf ${ex}-repr-mdl-naive-$now.tex

    # #expr vs bdd vs safa (with fixed global, MTL)
    # sed "s/MODS/aerial-mtl-global-expr, aerial-mtl-global-bdd, aerial-mtl-global-safa/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-repr-mtl-global-$now.tex
    # latexmk -shell-escape -pdf ${ex}-repr-mtl-global-$now.tex

    


    # #MTL vs MDL

    # #MTL vs MDL (with fixed expr, global)
    # sed "s/MODS/aerial-mdl-global-expr, aerial-mtl-global-expr/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-lang-global-expr-$now.tex
    # latexmk -shell-escape -pdf ${ex}-lang-global-expr-$now.tex

    # #MTL vs MDL (with fixed safa, global)
    # sed "s/MODS/aerial-mdl-global-safa, aerial-mtl-global-safa/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-lang-global-safa-$now.tex
    # latexmk -shell-escape -pdf ${ex}-lang-global-safa-$now.tex



    # #TOOLS

    # #Aerial MTL vs Aerial MDL vs Monpoly vs Montre (with fixed expr, global)
    # sed "s/MODS/aerial-mtl-global-expr, aerial-mdl-global-expr, monpoly, montre/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-tools-$now.tex
    # latexmk -shell-escape -pdf ${ex}-tools-$now.tex

    #Aerial MTL vs Aerial MDL vs Monpoly vs Montre (with fixed expr, global)
    sed "s/MODS/aerial-mtl-local-safa, monpoly, montre/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-tools-test-$now.tex
    latexmk -shell-escape -pdf ${ex}-tools-test-$now.tex


    ls ${ex}-* |  grep -v "pdf$" | xargs rm

done

