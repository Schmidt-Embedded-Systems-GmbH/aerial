#!/bin/bash

MAXIDX=$(./maxidx.sh)

mkdir -p logs

#custom or monpoly or constant or random
logs=$1

#constant and random traces are not tailored for specific formulas (use just constant 2)
if [[ "$logs" == "custom" || "$logs" == "monpoly" ]]
then
    parallel ./gen_logs_${logs}.sh  ::: `cat rates` ::: {2..4} ::: `eval echo {1..$MAXIDX}`
else
    parallel ./gen_logs_${logs}.sh  ::: `cat rates` ::: 2 ::: `eval echo {1..$MAXIDX}`
fi 