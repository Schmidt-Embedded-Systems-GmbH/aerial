#!/bin/bash
source functions.sh


MAXIDX=$(./maxidx.sh)

f1='! (true U[0,5] q)'
f2='! (p U[0,5] q)'
f3='! (p U[0,5] (q S[2,6] r))'
f4='! (p U[0,5] (q U[2,6] r))'

mf1='TRUE UNTIL [0, 5] q ()'
mf2='p () UNTIL [0, 5] q ()'
mf3='p () UNTIL [0, 5] (q () SINCE [2, 6] r ())'
mf4='p () UNTIL [0, 5] (q () UNTIL [2, 6] r ())'




mkdir -p formulas
echo $f1 > formulas/f1.formula
echo $f2 > formulas/f2.formula
echo $f3 > formulas/f3.formula
echo $f4 > formulas/f4.formula
echo $mf1 > formulas/monpoly_f1.formula
echo $mf2 > formulas/monpoly_f2.formula
echo $mf3 > formulas/monpoly_f3.formula
echo $mf4 > formulas/monpoly_f4.formula


for rate in `cat rates`;
do
#scale montre intervals to the event rate
frate=$((rate*5*2))
srate=$((rate*6*2))
trate=$((rate*2*2))

mof1='((!q||q)*;q)%(0,'${frate}')'
mof2='(p*;q)%(0,'${frate}')'
mof3='(p*;(r;q*)%('${trate}','${srate}'))%(0,'${frate}')'
mof4='(p*;(q*;r)%('${trate}','${srate}'))%(0,'${frate}')'

echo $mof1 > formulas/montre_f1_$rate.formula
echo $mof2 > formulas/montre_f2_$rate.formula
echo $mof3 > formulas/montre_f3_$rate.formula
echo $mof4 > formulas/montre_f4_$rate.formula
done


rm -rf tmp
mkdir -p tmp

rm -rf montre
mkdir -p montre

#custom or monpoly or random or constant
logs=$1

#Script for intervals
# echo "Tool, Rate, Formula, IDX, Space, Time" > results-${logs}.csv
# parallel ./aerial_interval.sh ::: `cat rates` ::: `cat forms` ::: `eval echo {1..8}` ::: `cat mods` ::: "${logs}" >> results-${logs}.csv


#Script for random formulas
echo "Tool, Rate, Formula, IDX, Space, Time" > results-${logs}.csv
parallel ./aerial_formula.sh ::: `cat rates` ::: `cat forms` ::: `eval echo {0..79}` ::: `cat mods` ::: "${logs}" >> results-${logs}.csv

#Script for rates
# echo "Tool, Rate, Formula, IDX, Space, Time" > results-${logs}.csv
# parallel ./aerial.sh ::: `cat rates` ::: `eval echo {1..4}` ::: `eval echo {1..8}` ::: `cat mods` ::: "${logs}" >> results-${logs}.csv



 #./process_results.sh ${logs} > results-${logs}-final.csv

 #./visualize_results.sh ${logs}