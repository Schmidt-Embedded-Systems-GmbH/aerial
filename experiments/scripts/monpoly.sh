#!/bin/bash

MONPOLY="./monpoly"
TIME="/usr/bin/time -l"

rate=$1
form=$2
i=$3
space=$(($TIME $MONPOLY -sig f.sig -formula formulas/monpoly_f$form.formula -log logs/tr${form}_${i}_${rate}.log) 2>&1 | grep "maximum resident set size" | sed "s/[ a-z]*//g")
echo "monpoly rate: $rate formula: $form idx: $i space: $space"