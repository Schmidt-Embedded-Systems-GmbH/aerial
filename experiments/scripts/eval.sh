#!/bin/bash

MONPOLY="./monpoly"
AERIAL="../../aerial"
TIME="/usr/bin/time -l"

f1='Until (lclosed_rclosed_BI 0 10, Bool true, P "P1")'
f2='Until (lclosed_rclosed_BI 0 10, P "P0", P "P1")'
f3='Until (lclosed_rclosed_BI 0 10, P "P0", Since (B (lclosed_rclosed_BI 2 6), P "P1", P "P2"))'
f4='Until (lclosed_rclosed_BI 0 10, P "P0", Until (lclosed_rclosed_BI 2 6, P "P1", P "P2"))'

mf1='TRUE UNTIL [0, 10] P1 ()'
mf2='P0 () UNTIL [0, 10] P1 ()'
mf3='P0 () UNTIL [0, 10] (P1 () SINCE [2, 6] P2 ())'
mf4='P0 () UNTIL [0, 10] (P1 () UNTIL [2, 6] P2 ())'

mkdir -p formulas
echo $f1 > formulas/f1.formula
echo $f2 > formulas/f2.formula
echo $f3 > formulas/f3.formula
echo $f4 > formulas/f4.formula
echo $mf1 > formulas/monpoly_f1.formula
echo $mf2 > formulas/monpoly_f2.formula
echo $mf3 > formulas/monpoly_f3.formula
echo $mf4 > formulas/monpoly_f4.formula

function print_mode {
   if [ "$1" -eq "0" ]
   then
     echo -n "naive  "
   elif [ "$1" -eq "1" ]
   then
     echo -n "local  "
   else
     echo -n "global "
   fi
}

for rate in `cat rates | head -n4`
do
  for form in {1..4};
  do
    for mode in {0..2};
    do
      for i in {1..3};
      do
  		  ($TIME $AERIAL -mode $mode -fmla formulas/f$form.formula -log logs/tr${form}_${i}_${rate}.log -out /dev/null) 2>&1 >/dev/null | grep "maximum resident set size" | sed "s/[ a-z]*//g" > res;
      done;
      print_mode $mode;
      echo -n " rate: $rate formula: $form ";
      perl -lane '$a+=$_ for(@F);$f+=scalar(@F);END{print "space: ".$a/($f * 1024 * 1024)." MB"}' res
      rm res
    done

    for i in {1..3};
    do
      ($TIME $MONPOLY -sig f.sig -formula formulas/monpoly_f$form.formula -log logs/tr${form}_${i}_${rate}.log) 2>&1 >/dev/null | grep "maximum resident set size" | sed "s/[ a-z]*//g" > res
    done;
    echo -n "monpoly rate: $rate formula: $form ";
    perl -lane '$a+=$_ for(@F);$f+=scalar(@F);END{print "space: ".$a/($f * 1024 * 1024)." MB"}' res
    rm res
  done
done