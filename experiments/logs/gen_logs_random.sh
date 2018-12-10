#!/bin/bash
source ../params.cfg

rate=$1
form=$2
i=$3

if [ ! -z "$4" ]
then
MAXTS=$4
fi

mkdir -p random


for ts in `seq 1 $MAXTS`; do for j in `seq 1 $rate`; do [[ $((RANDOM % 2)) = 0 ]] && p="p () " || p=""; [[ $((RANDOM % 2)) = 0 ]] && q="q () " || q=""; [[ $((RANDOM % 2)) = 0 ]] && r="r () " || r=""; echo "@$ts $p$q$r"; done; done > random/tr${form}_${i}_${rate}.log
echo "generated log ${i} for formula ${form} with rate ${rate} using the random generator";

#converting to montre format
./convert_logs.sh random/tr${form}_${i}_${rate}.log $rate > random/montre_tr${form}_${i}_${rate}.log
