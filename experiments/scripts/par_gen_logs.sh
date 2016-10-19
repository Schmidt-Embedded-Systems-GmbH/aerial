#!/bin/bash

MAXIDX=10

mkdir -p logs
parallel ./gen_logs.sh  ::: `cat rates` ::: {1..4} ::: `eval echo {1..$MAXIDX}`