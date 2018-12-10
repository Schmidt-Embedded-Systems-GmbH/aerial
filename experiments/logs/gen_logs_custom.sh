#!/bin/bash
source ../params.cfg

rate=$1
form=$2
i=$3

if [ ! -z "$4" ]
then
MAXTS=$4
fi

mkdir -p custom

#custom generator
./gen_log${form}.sh ${rate} ${MAXTS} > custom/tr${form}_${i}_${rate}.log 2> /dev/null
echo "generated log ${i} for formula ${form} with rate ${rate} using the custom generator";

#converting to montre
./convert_logs.sh custom/tr${form}_${i}_${rate}.log $rate > custom/montre_tr${form}_${i}_${rate}.log
