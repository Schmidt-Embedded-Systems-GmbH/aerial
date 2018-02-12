#!/bin/bash
source ./params.cfg


system=`uname`

if [ "$system" == "Linux" ]
then
  DATE="date"
  TIMEOUT="timeout"
  AWK="gawk"
  TIME="/usr/bin/time -v"
else
  DATE="gdate"
  TIMEOUT="gtimeout"
  AWK="gawk"
  TIME="/usr/bin/time -l"
fi


function run {
    #command to run
    local cmd="$1"
    #params to print
    local params="$2"

    #run the command, parse results...
    local ts=$($DATE +%s%N)
    local result=$(eval "$TIME $TIMEOUT $cmd")
    local time=$((($($DATE +%s%N) - $ts)/1000000)) 

    #DEBUG
    #echo $result

    if [ "$system" == "Linux" ]
    then
      local space=$(echo $result | cut -d ":" -f15 | cut -d " " -f2)
      local space=$((space*1024))
    else
      local space=$(echo $result | cut -d " " -f7)
    fi

    # step 3 (see below)
    if [ "$time" -gt "$TO" ]
    then
      local time="${time} (timeout)"
      echo "timeout" >> $tmpfile
    fi

    #print
    echo "$params, $space, $time"

}
