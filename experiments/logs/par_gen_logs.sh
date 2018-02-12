#!/bin/bash
source ../params.cfg

function generate {
local logs=$1

mkdir -p $logs
#constant and random traces are not tailored for specific formulas (use empty string)
    if [[ "$logs" == "custom" || "$logs" == "monpoly" ]]
    then
        parallel -P 24 ./gen_logs_${logs}.sh  ::: `eval echo $RATES` ::: {1..4} ::: `eval echo {1..$MAXIDX}` 2> /dev/null
    else
        parallel -P 24 ./gen_logs_${logs}.sh  ::: `eval echo $RATES` ::: "" ::: `eval echo {1..$MAXIDX}` 2> /dev/null
    fi 
}

for l in $LOGS; do
    generate $l
done



