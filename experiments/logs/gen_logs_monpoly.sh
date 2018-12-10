#!/bin/bash
make -C ../../ generate-monpoly > /dev/null 2>&1

rate=$1
form=$2
i=$3

if [ ! -z "$4" ]
then
MAXTS=$4
fi

mkdir -p monpoly

#ocamlbuild gen_log.native

#monpoly generator
./gen_log.native -time_span 100 -event_rate $rate -seed_index $i -policy P$form | sed -n '/\@101/q;p' 2> /dev/null > monpoly/tr${form}_${i}_${rate}.log
echo "generated log ${i} for formula ${form} with rate ${rate} using the monpoly generator";

#convert to montre
./convert_logs.sh monpoly/tr${form}_${i}_${rate}.log $rate > monpoly/montre_tr${form}_${i}_${rate}.log
