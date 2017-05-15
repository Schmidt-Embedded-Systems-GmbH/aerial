#!/bin/bash

source ./functions.sh

logs=$1
type=$2

mods=$(format_mode)
mkdir -p figures
now=$($DATE +"%Y_%m_%d-%H-%M")
sed "s/MODS/$mods/g" ./plots-${type}.tex > plots-${now}.tex

latexmk -shell-escape -pdf plots-${now}.tex

open plots-${now}.pdf