#!/bin/bash

rate=$1
form=$2
i=$3
logdir="logs/custom"

mkdir -p $logdir

#custom generator
./gen_log${form}.sh ${rate} > $logdir/tr${form}_${i}_${rate}.log;
echo "generated log ${i} for formula ${form} with rate ${rate}";

#converting to montre
./convert_logs.sh $logdir/tr${form}_${i}_${rate}.log $rate > $logdir/montre_tr${form}_${i}_${rate}.log
