#!/bin/bash

source functions.sh

logs=$1

mods=$(format_mode)
mkdir -p figures
now=$(date +"%Y_%m_%d-%H-%M")
sed "s/MODS/$mods/g" ./plots.tex > plots-$now.tex

latexmk -shell-escape -pdf plots-$now.tex