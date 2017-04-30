#!/bin/bash


rate=$2

prev=1
#converting generated log to Montre format
cat $1 | sed  -E -e "s/\@//g" -e "s/\(\)//g" -e "s/  q/q/g" -e "s/  r/r/g" -e "s/1$/1 --/g" | while read -r ts ev; do 

if [ "$ts" -eq "$prev" ] 
then
    echo "0 $ev"
else
    echo "1 $ev"
fi
prev=$ts

done 

