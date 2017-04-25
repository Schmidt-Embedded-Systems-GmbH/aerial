#!/bin/bash

MAXIDX=10

f1='! (true U[0,5] q)'
f2='! (p U[0,5] q)'
f3='! (p U[0,5] (q S[2,6] r))'
f4='! (p U[0,5] (q U[2,6] r))'

mf1='NOT (TRUE UNTIL [0, 5] q ())'
mf2='NOT (p () UNTIL [0, 5] q ())'
mf3='NOT (p () UNTIL [0, 5] (q () SINCE [2, 6] r ()))'
mf4='NOT (p () UNTIL [0, 5] (q () UNTIL [2, 6] r ()))'

mof1='!((((!q)||q)*;q)%(0,5))'
mof2='(p*;q)%(0,5)'
mof3='(p*;(r;q*)%(2,6))%(0,5)'
mof4='(p*;(q*;r)%(2,6))%(0,5)'

mkdir -p formulas
echo $f1 > formulas/f1.formula
echo $f2 > formulas/f2.formula
echo $f3 > formulas/f3.formula
echo $f4 > formulas/f4.formula
echo $mf1 > formulas/monpoly_f1.formula
echo $mf2 > formulas/monpoly_f2.formula
echo $mf3 > formulas/monpoly_f3.formula
echo $mf4 > formulas/monpoly_f4.formula
echo $mof1 > formulas/montre_f1.formula
echo $mof2 > formulas/montre_f2.formula
echo $mof3 > formulas/montre_f3.formula
echo $mof4 > formulas/montre_f4.formula

rm -rf tmp
mkdir -p tmp

#custom or monpoly
logs=$1


echo "Tool, Rate, Formula, IDX, Space, Time" > results.csv
parallel ./aerial.sh ::: `cat rates` ::: {1..4} ::: `eval echo {1..$MAXIDX}` ::: {0..7} ::: "logs/${logs}"" >> results-${logs}.csv

echo "Tool, Rate, Formula, Space, Time" > results-${logs}-avg.csv
cat results-${logs}.csv | grep -v Time | grep -v timeout | gawk '{m[$1][$2][$3]+=$5;t[$1][$2][$3]+=$6;n[$1][$2][$3]++}END{for(i in t){for(j in t[i]){for(k in t[i][j]){print i, j, k, m[i][j][k]/(1 < n[i][j][k] ? n[i][j][k] : 1)/1024/1024 ", " t[i][j][k]/(1 < n[i][j][k] ? n[i][j][k] : 1) }}}}' >> results-${logs}-avg.csv
cat results-${logs}-avg.csv | sort -n -k 2 > results-${logs}-sorted-avg.csv

mkdir figures
latexmk -shell-escape -pdf plots.tex
