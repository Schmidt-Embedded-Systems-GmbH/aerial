#!/bin/bash

RATE=$1
VAR=10
MAXTS=100
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
  local b=$(( $RANDOM % ($A + $B) ))
  if [[ "$a" -lt "$A" && "$b" -lt "$B" ]]
  then
    echo "@$ts P0 () P1 ()"
  elif [[ "$a" -lt "$A" ]]
  then
    echo "@$ts P0 ()"
  elif [[ "$b" -lt "$B" ]]
  then
    echo "@$ts P1 ()"
  else
    echo "@$ts"
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