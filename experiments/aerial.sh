#!/bin/bash

#to use gdate for precise time measurement, 
#one needs to install coreutils on Mac OS
# e.g. brew install coreutils

AERIAL=$(which aerial)
MONPOLY=$(which monpoly)
MONTRE=$(which montre)
TIMEOUT="gtimeout 100s"

if [[ -z "$AERIAL" || -z "$MONPOLY" || -z "$MONTRE" ]]
then 
echo "Tools not installed, run 'make install'..."
exit
fi

TIME="/usr/bin/time -l"

function print_mode {
#mode can be 0 -> aerial MTL naive,
#            1 -> aerial MTL local,
#            2 -> aerial MTL global,
#            3 -> aerial MDL naive,
#            4 -> aerial MDL local,
#            5 -> aerial MDL global,
#            6 -> monpoly,
#            7 -> montre
   if [ "$1" -eq "0" ]
   then
     echo "aerial_MTL_naive"
   elif [ "$1" -eq "1" ]
   then
     echo "aerial_MTL_local"
   elif [ "$1" -eq "2" ]
   then
     echo "aerial_MTL_global"
   elif [ "$1" -eq "3" ]
   then
     echo "aerial_MDL_naive"
   elif [ "$1" -eq "4" ]
   then
     echo "aerial_MDL_local"
   elif [ "$1" -eq "5" ]
   then
     echo "aerial_MDL_global"
   elif [ "$1" -eq "6" ]
   then
     echo "monpoly"
   else
     echo "montre"
   fi
}

function run {
    #command to run
    local cmd=$1
    #params to print
    local params=$2

    #run the command, parse results...
    local ts=$(gdate +%s%N)
    local result=$(eval "$TIMEOUT $TIME $cmd")
    local time=$((($(gdate +%s%N) - $ts)/1000000)) 
    local space=$(echo $result | cut -d " " -f7)
    #local time=$(echo $result | cut -d " " -f1)

    if [ -z "$space" ]
    then
      space="timeout"
      time="timeout"
    fi

    #print
    echo "$params, $space, $time"

}

rate=$1
form=$2
if [ "$form" -eq "1" ]
then
  trace=2
else
  trace=$form
fi

i=$3
mode=$4

modestr=$(print_mode $mode)
params="$modestr, $rate, $form, $i"


if [ "$mode" -eq "6" ]
then
  cmd="$MONPOLY -sig f.sig -formula formulas/monpoly_f$form.formula -log logs/tr${trace}_${i}_${rate}.log 2>&1 >/dev/null"
elif [ "$mode" -lt "6" ]
then
  if [ "$mode" -lt "3" ]
  then 
      lang="-mtl"
  else
      lang="-mdl"
      mode=$(($mode - 3))
  fi 
  cmd="$AERIAL -mode $mode $lang -fmla formulas/f$form.formula -log  logs/tr${trace}_${i}_${rate}.log -out /dev/null 2>&1"
else
  cmd="$MONTRE -i -e '`cat formulas/montre_f$form.formula`' -o /dev/null 'logs/montre_tr${trace}_${i}_${rate}.log' 2>&1 > /dev/null"
fi

run "$cmd" "$params"

#echo $cmd