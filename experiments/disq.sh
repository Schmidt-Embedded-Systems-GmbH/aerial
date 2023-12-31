#!/bin/bash
source ./functions.sh

test=$1
mode=$2
rate=$3
form=$4

function find_prev {

    local p=""
    for i in $2; do
        if [[ "$1" = "$i" ]]; then
            break
        fi
        p=$i
    done
    echo $p
}

#check for disqualification in the following way:
#  1. if the tool+formula were disqualified in the previous rate (exsistance of the $prevstopfile)
#     stop and genereate $stopfile.
#  2. otherwise, check how many times the tool+formula timed out (in $prevtmpfile)
#      - if -eq $MAXIDX, disqualify and genreate $prevstopfile and $stopfile
#      - otherwise proceed
#  3. after running the tool+formula, if it times out, write a line in the file for the current rate ($tmpfile)


if [[ "$test" = "rate" ]];
then 
    prev=$(find_prev $rate "$RATES")
    threshold=$((RIDX*RFIDX))

    #path to the current timeout counting file
    tmpfile="tmp/TO${mode}_${rate}_${form}.tmp"
    #path to the previous timeout counting file
    prevtmpfile="tmp/TO${mode}_${prev}_${form}.tmp"

    #path to the current STOP file
    stopfile="tmp/STOP${mode}_${rate}_${form}.tmp"
    #path to the previous STOP file
    prevstopfile="tmp/STOP${mode}_${prev}_${form}.tmp"


elif [[ "$test" = "formula" ]];
then 
    prev=$(find_prev $form "$FORMS")
    threshold=$((FIDX*FFIDX))

    #path to the current timeout counting file
    tmpfile="tmp/TO${mode}_${form}_${rate}.tmp"
    #path to the previous timeout counting file
    prevtmpfile="tmp/TO${mode}_${prev}_${rate}.tmp"

    #path to the current STOP file
    stopfile="tmp/STOP${mode}_${form}_${rate}.tmp"
    #path to the previous STOP file
    prevstopfile="tmp/STOP${mode}_${prev}_${rate}.tmp"
    

elif [[ "$test" = "interval" ]];
then 
    #TODO: think about the interval
    prev=$(find_prev $form "$FORMS")
    threshold=$((IIDX*IFIDX))

    #path to the current timeout counting file
    tmpfile="tmp/TO${mode}_${form}_${rate}.tmp"
    #path to the previous timeout counting file
    prevtmpfile="tmp/TO${mode}_${prev}_${rate}.tmp"

    #path to the current STOP file
    stopfile="tmp/STOP${mode}_${form}_${rate}.tmp"
    #path to the previous STOP file
    prevstopfile="tmp/STOP${mode}_${prev}_${rate}.tmp"

else
    #no disq scheme
    exit 0
fi



# step 1
if [ -f $prevstopfile ]
then
    touch $stopfile
    exit -1
fi
    #DEBUG
    #(>&2 echo "disq: " $prevtmpfile)

#step 2
if [ -f $prevtmpfile ]
then
  tos=$(wc -l $prevtmpfile | $AWK '{$1=$1;print}' | cut -d " " -f1)

    #DEBUG
    #(>&2 echo "disq: " $tos)

  if [ "$tos" -eq "$threshold" ]
  then 
    touch $prevstopfile
    touch $stopfile
    exit -1
  fi
fi

echo $tmpfile
