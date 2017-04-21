#!/bin/bash

MONPOLY="./monpoly"
TIME="/usr/bin/time -l"

rate=$1
form=$2
i=$3
trace=$4
cmd="$TIME $MONPOLY -sig f.sig -formula formulas/monpoly_f$form.formula -log logs/tr${trace}_${i}_${rate}.log 2>&1"
params "monpoly rate: $rate formula: $form idx: $i"
./run.sh $cmd $params
