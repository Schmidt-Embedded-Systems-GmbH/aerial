#!/bin/bash

RATE=$1
VAR=100
MAXTS=$2
A=1000
if [ "$RATE" -le "1000" ]
then
  B=10
else
  B=1
fi

function stutter {
  if [ "$(($RANDOM % 2))" -eq "0" ]
  then
    echo $(($RATE + $RANDOM % ($RATE * $VAR / 100)))
  else
    echo $(($RATE - $RANDOM % ($RATE * $VAR / 100)))
  fi
}

function gen {
  local ts=$1
  local a=$(( $RANDOM % ($A + $B) ))
  local c=$(($RANDOM % 3))
  if [[ "$a" -lt "$A" ]]
  then
    echo "@$ts p () q () r ()"
  elif [[ "$c" -eq "0" ]]
  then
    echo "@$ts p () q ()"
  elif [[ "$c" -eq "1" ]]
  then
    echo "@$ts q () r ()"
  else
    echo "@$ts p () r ()"
  fi
}

for ts in `eval echo {1..$MAXTS}`;
do
  ST=$(stutter);
  for i in `eval echo {1..$ST}`;
  do
    gen $ts
  done
done