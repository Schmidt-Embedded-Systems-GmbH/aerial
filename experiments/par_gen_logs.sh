#!/bin/bash

MAXIDX=10

mkdir -p logs

#custom or monpoly
logs=$1

parallel ./gen_logs_${logs}.sh  ::: `cat rates` ::: {2..4} ::: `eval echo {1..$MAXIDX}`