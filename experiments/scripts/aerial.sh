#!/bin/bash

AERIAL="./aerial"
TIME="/usr/bin/time -l"

function print_mode {
   if [ "$1" -eq "0" ]
   then
     echo "naive  "
   elif [ "$1" -eq "1" ]
   then
     echo "local  "
   else
     echo "global "
   fi
}

rate=$1
form=$2
i=$3
mode=$4
if [ "$mode" -eq "3" ]
then
  ./monpoly.sh $rate $form $i;
else
  modestr=$(print_mode $mode)
  space=$(($TIME $AERIAL -mode $mode -fmla formulas/f$form.formula -log  logs/tr${form}_${i}_${rate}.log -out /dev/null) 2>&1 | grep "maximum resident set size" | sed "s/[ a-z]*//g")
  echo "$modestr rate: $rate formula: $form idx: $i space: $space"
fi
