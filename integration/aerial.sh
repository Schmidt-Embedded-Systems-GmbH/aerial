#!/bin/bash



MAXIDX=`cat maxidx`

DATE="gdate"
TIMEOUT="gtimeout"
AWK="gawk"
TIME="/usr/bin/time -l"
TIMEOUT="$TIMEOUT 10s"
AERIAL=$(which aerial)

rate=$1
form=$2
log_index=$3
fma_index=$4
lang=$5
offset=$6
logdir="logs/random"

function run {
    #command to run
    local cmd="$1"
    #params to print
    local params="$2"
    local idxs="$3"

    #run the command, parse results...
    local ts=$($DATE +%s%N)
    local result=$(eval "$TIME $TIMEOUT $cmd")
    local time=$((($($DATE +%s%N) - $ts)/1000000)) 
    local space=$(echo $result | cut -d " " -f7)

    # the actual test 
    # ...
      # read bounds
    smin=$(cat db.csv | egrep "$params," | cut -d "," -f5)
    smax=$(cat db.csv | egrep "$params," | cut -d "," -f6)

    tmin=$(cat db.csv | egrep "$params," | cut -d "," -f9)
    tmax=$(cat db.csv | egrep "$params," | cut -d "," -f10)
      # apply offset
    smin=$(echo "$smin * (1 - $offset)" | bc -l)
    smax=$(echo "$smax * (1 + $offset)" | bc -l)
    tmin=$(echo "$tmin * (1 - $offset)" | bc -l)
    tmax=$(echo "$tmax * (1 + $offset)" | bc -l)
    

    if [ $(echo "$space < $smin" | bc -l) -eq 1 ];
    then
      >&2 echo "Warning: used space (= $space B) is LESS than the bound (= $smin B) for ($params, $idxs)"
    fi
    
    if [ $(echo "$smax < $space" | bc -l) -eq 1 ];
    then
      >&2 echo "Warning: used space (= $space B) is MORE than the bound (= $smax B) for ($params, $idxs)"
    fi

     if [ $(echo "$time < $tmin" | bc -l) -eq 1 ];
    then
      >&2 echo "Warning: used time (= $time ms) is LESS than the bound (= $tmin ms) for ($params, $idxs)"
    fi
    
    if [ $(echo "$tmax < $time" | bc -l) -eq 1 ];
    then
      >&2 echo "Warning: used time (= $time ms) is MORE than the bound (= $tmax ms) for ($params, $idxs)"
    fi

    #print
    echo "$params, $idxs, $space, $time"

}



params="$form, $rate"
idxs="$fma_index, $log_index"

cmd="$AERIAL -mode 1 -$lang -fmla formulas/r${form}_${fma_index}.formula -log  ${logdir}/tr2_${log_index}_${rate}.log -out /dev/null 2>&1"

run "$cmd" "$params" "$idxs"

