#!/bin/bash

MAXIDX=10

f1='true U[0,5] P1'
f2='P0 U[0,5] P1'
f3='P0 U[0,5] (P1 S[2,6] P2)'
f4='P0 U[0,5] (P1 U[2,6] P2)'

mf1='TRUE UNTIL [0, 5] P1 ()'
mf2='P0 () UNTIL [0, 5] P1 ()'
mf3='P0 () UNTIL [0, 5] (P1 () SINCE [2, 6] P2 ())'
mf4='P0 () UNTIL [0, 5] (P1 () UNTIL [2, 6] P2 ())'

mkdir -p formulas
echo $f1 > formulas/f1.formula
echo $f2 > formulas/f2.formula
echo $f3 > formulas/f3.formula
echo $f4 > formulas/f4.formula
echo $mf1 > formulas/monpoly_f1.formula
echo $mf2 > formulas/monpoly_f2.formula
echo $mf3 > formulas/monpoly_f3.formula
echo $mf4 > formulas/monpoly_f4.formula

parallel ./aerial.sh ::: `cat rates` ::: {1..4} ::: `eval echo {1..$MAXIDX}` ::: {1..3}