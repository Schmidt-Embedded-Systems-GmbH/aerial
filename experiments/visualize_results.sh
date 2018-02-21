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

    #TODO MDL
    #NAIVE vs LOCAL vs GLOBAL (with fixed expr, MDL)
    sed "s/MODS/aerial-mtl-naive-expr, aerial-mtl-local-expr, aerial-mtl-global-expr/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-mode-$now.tex
    latexmk -shell-escape -pdf ${ex}-mode-$now.tex

    #TODO MDL
    #expr vs bdd vs safa (with fixed global, MDL)
    sed "s/MODS/aerial-mtl-global-expr, aerial-mtl-global-bdd, aerial-mtl-global-safa/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-repr-$now.tex
    latexmk -shell-escape -pdf ${ex}-repr-$now.tex

    #MTL vs MDL (with fixed expr, global)
    sed "s/MODS/aerial-mtl-global-expr, aerial-mdl-global-expr/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-lang-$now.tex
    latexmk -shell-escape -pdf ${ex}-lang-$now.tex

    #TODO MDL
    #Aerial MTL vs Aerial MDL vs Monpoly vs Montre (with fixed expr, global)
    sed "s/MODS/aerial-mtl-global-expr, monpoly, montre/g;s/PATH/$path/g" ./${ex}.tex > ${ex}-tools-$now.tex
    latexmk -shell-escape -pdf ${ex}-tools-$now.tex

    ls ${ex}-* |  grep -v "pdf$" | xargs rm

done

