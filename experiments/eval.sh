#!/bin/bash
source ./functions.sh


#Used for disqualification
rm -rf tmp
mkdir -p tmp

#backup the previous run
backup="run-$(date +%Y%m%d%H%M%S)"
mkdir $backup
mv results-* $backup

# Reuse traces and formulas
# ls -l logs/ | grep ^d | tr -s " " | cut -d " " -f9 | xargs -I J mv logs/J $backup
# ls -l formulas/ | grep ^d | tr -s " " | cut -d " " -f9 | xargs -I J mv formulas/J $backup
# cd formulas
# ./par_gen_formulas.sh
# cd ..
# cd logs
# ./par_gen_logs.sh
# cd ..

#Type of experiment: "rate" or "formula" or "interval"
if [ ! -z "$1" ]
then
TEST=$1
fi

#Logs: "custom" or "monpoly" or "random" or "constant"
if [ ! -z "$2" ]
then
LOGS=$2
fi

echo "Running evaluation"
echo "<type of experiments> = $TEST"
echo "<type of logs> = $LOGS"


for t in $TEST; do

    if [ "$t" == "rate" ]
    then
        f=$RFORMS
        fidx=$RFIDX
        logs=$RLOGS
        idx=$RIDX
        rates=$RRATES
    elif [ "$t" == "formula" ]
    then 
        f=$FFORMS
        fidx=$FFIDX
        logs=$FLOGS
        idx=$FIDX
        rates=$FRATES 
    elif [ "$t" == "interval" ]
    then
        f=$IFORMS
        fidx=$IFIDX
        logs=$ILOGS
        idx=$IIDX
        rates=$IRATES 
    else
    echo "Unknown experiment type"  
    fi

    for l in $logs; do

        echo "Tool, Rate, Formula, IDX, Space, Time" > results-${t}-${l}.csv

        parallel ./run.sh ::: `eval echo $TOOLS` ::: `eval echo $f` ::: `eval echo {1..$fidx}` ::: `eval echo $l` ::: `eval echo {1..$idx}` ::: `eval echo $rates` ::: `eval echo $t` >> results-${t}-${l}.csv 2> /dev/null

        ./process_results.sh ${t} ${l} > results-${t}-${l}-final.csv

        #./visualize_results.sh ${logs} ${t}

    done

done
 