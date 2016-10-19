#!/bin/bash

mkdir tmp
mkdir -p logs
cp PrioQueue.ml tmp
cp gen_log_f*.ml tmp
cd tmp

for form in {1..4};
do
  ocamlc -o gen_log_f$form PrioQueue.ml gen_log_f$form.ml 2> /dev/null;
done


for rate in `cat rates`;
do
  for form in {1..4};
  do
    for i in {1..25};
    do
      ./gen_log_f$form -event_rate $rate -seed_index $RANDOM > ../logs/tr${form}_${i}_${rate}.log;
      echo "generated log ${i} for formula ${form} with rate ${rate}";
    done
  done
done

cd ..
rm -rf tmp