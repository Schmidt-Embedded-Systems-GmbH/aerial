#!/bin/bash

#to use gdate for precise time measurement, 
#one needs to install coreutils on Mac OS
# e.g. brew install coreutils

#use helper functions
source ./functions.sh

MAXIDX=80

TIMEOUT="$TIMEOUT 100s"

AERIAL=$(which aerial)
# AERIAL=./aerial.native
MONPOLY=$(which monpoly)
MONTRE=$(which montre)

#this should be uncommented in the official version
# AERIAL=$(which aerial)
# MONPOLY=$(which monpoly)
# MONTRE=$(which montre)
# if [[ -z "$AERIAL" || -z "$MONPOLY" || -z "$MONTRE" ]]
# then 
# echo "Tools not installed, run 'make install'..."
# exit
# fi

#Start of the script

rate=$1
form=$2
index=$3
mode=$4
logs=$5
logdir="logs/$logs"

i=$((index % 10 + 1))

j=$((index / 10 + 1))


modestr=$(print_mode $mode)

#check for disqualification in the following way:
#  1. if the tool+formula were disqualified in the previous rate (exsistance of the $prevstopfile)
#     stop and genereate $stopfile.
#  2. otherwise, check how many times the tool+formula timed out (in $prevtmpfile)
#      - if -eq $MAXIDX, disqualify and genreate $prevstopfile and $stopfile
#      - otherwise proceed
#  3. after running the tool+formula, if it times out, write a line in the file for the current rate ($tmpfile)

#path to the current timeout counting file
tmpfile="tmp/TO${mode}_${form}.tmp"
#path to the previous timeout counting file
prevform=$(cat forms | egrep -B1 "^$form$" | head -1)
prevtmpfile="tmp/TO${mode}_${prevform}.tmp"

#path to the current stop file
stopfile="tmp/STOP${mode}_${form}.tmp"
#path to the previous stop file
prevstopfile="tmp/STOP${mode}_${prevform}.tmp"

# step 1
if [ -f $prevstopfile ]
then
echo "$modestr, $rate, $form, $index, disq, disq"
touch $stopfile
exit
fi

#step 2
if [ -f $prevtmpfile ]
then
  tos=$(wc -l $prevtmpfile | $AWK '{$1=$1;print}' | cut -d " " -f1)
  # tos=$(wc -l $prevtmpfile | tr -s " " | cut -d " " -f2)
  if [ "$tos" -gt "$MAXIDX" ]
  then 
  echo "$modestr, $rate, $form, $index, disq, disq"
  touch $prevstopfile
  touch $stopfile
  exit
  fi
fi


trace=2


#constant and random traces are not tailored for specific formulas
if [[ "$logs" == "constant" || "$logs" == "random" ]]
then
  trace=2
fi


params="$modestr, $rate, $form, $index"


if [ "$mode" -eq "6" ]
then
  cmd="$MONPOLY -sig f.sig -formula formulas/monpoly_r${form}_${i}.formula -log ${logdir}/tr${trace}_${j}_${rate}.log -negate 2>&1 >/dev/null"
elif [ "$mode" -eq "7" ]
then 
  cmd="$MONTRE -i -e '`cat formulas/montre_r${form}_${rate}_${i}.formula`' '${logdir}/montre_tr${trace}_${j}_${rate}.log' 2>&1 > /dev/null"
elif [ "$mode" -eq "8" ]
then 
  cmd="$AERIAL -mtl-bdd -fmla formulas/r${form}_${i}.formula -log  ${logdir}/tr${trace}_${j}_${rate}.log -out /dev/null 2>&1"
elif [ "$mode" -eq "9" ]
then 
  cmd="$AERIAL -mdl-bdd -fmla formulas/r${form}_${i}.formula -log  ${logdir}/tr${trace}_${j}_${rate}.log -out /dev/null 2>&1"
elif [ "$mode" -lt "6" ]
then
  if [ "$mode" -lt "3" ]
  then 
      lang="-mtl"
  else
      lang="-mdl"
      mode=$(($mode - 3))
  fi 
  cmd="$AERIAL -mode $mode $lang -fmla formulas/r${form}_${i}.formula -log  ${logdir}/tr${trace}_${j}_${rate}.log -out /dev/null 2>&1"
else
  echo "Unrecognized mode!"
fi

#echo $cmd

run "$cmd" "$params"

