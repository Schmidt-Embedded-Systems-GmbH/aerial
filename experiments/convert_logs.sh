#!/bin/bash


rate=$2
buffer=0
#assumption: sampling rate that is twice the event rate is enough
unitspersecond=$((rate*2))

prev=1
#converting generated log to Montre format
cat $1 | sed  -E -e "s/\@//g" -e "s/\(\)//g" -e "s/  q/q/g" -e "s/  r/r/g" -e "s/1$/1 --/g" | while read -r ts ev; do 

if [ -z "$ev" ]
then
    ev="--"
fi

if [ "$ts" -eq "$prev" ] 
then
    echo "1 $ev"
    buffer=$((buffer+1))
else
    delta=$((unitspersecond-buffer))
    if [ $delta -lt 0 ]
    then 
    >&2 echo "Error!"
    exit
    else  
        echo "$delta $ev"
    fi
    buffer=1
fi
prev=$ts

done 

