#!/bin/bash

rate=$1
form=$2
i=$3
./gen_log${form}.sh ${rate} > logs/tr${form}_${i}_${rate}.log;
echo "generated log ${i} for formula ${form} with rate ${rate}";

./convert_logs.sh logs/tr${form}_${i}_${rate}.log > logs/montre_tr${form}_${i}_${rate}.log