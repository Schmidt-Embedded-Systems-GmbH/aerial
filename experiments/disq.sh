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

#path to the current timeout counting file
tmpfile="tmp/TO${mode}_${rate}_${form}.tmp"
#path to the previous timeout counting file

if [[ "$test" = "rate" ]];
then 
    prev=$(find_prev $rate $RATES)

elif [[ "$test" = "formula" ]];
then 
    prev=$(find_prev $form $FORMS)

elif [[ "$test" = "interval" ]];
then 
    prev=$(find_prev $form $FORMS)

else
    #no disq scheme
    exit 0

fi

prevtmpfile="tmp/TO${mode}_${prev}_${form}.tmp"


#path to the current stop file
stopfile="tmp/STOP${mode}_${rate}_${form}.tmp"
#path to the previous stop file
prevstopfile="tmp/STOP${mode}_${prevrate}_${form}.tmp"

# step 1
if [ -f $prevstopfile ]
then
touch $stopfile
exit -1
fi

#step 2
if [ -f $prevtmpfile ]
then
  tos=$(wc -l $prevtmpfile | $AWK '{$1=$1;print}' | cut -d " " -f1)
  
  if [ "$tos" -eq "$MAXIDX" ]
  then 
  touch $prevstopfile
  touch $stopfile
  exit -1
  fi
fi

