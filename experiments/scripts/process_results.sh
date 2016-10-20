#!/bin/bash

rm -r tmp
mkdir tmp

for form in {1..4};
do
  rm -f f${form}_results.txt
  grep "formula: $form " results.txt > tmp/f${form}.txt;
  for tool in "naive" "global" "local" "monpoly";
  do
    grep $tool tmp/f${form}.txt > tmp/f${form}_${tool}.txt;
    for rate in `cat rates`;
    do
      grep "rate: $rate " tmp/f${form}_${tool}.txt > tmp/f${form}_${tool}_${rate}.txt;
      sed -i '' 's/.*space: //g' tmp/f${form}_${tool}_${rate}.txt;
      awk '{for(i=1;i<=NF;i++) {sum[i] += $i; sumsq[i] += ($i)^2}}
          END {for (i=1;i<=NF;i++) {
          printf "%d %f %f \n", "'"$rate"'", sum[i]/NR/1024/1024, sqrt((sumsq[i]-sum[i]^2/NR)/NR)/1024/1024}
         }' tmp/f${form}_${tool}_${rate}.txt >> tmp/f${form}_${tool}_ave.txt;
    done
    echo "$tool" >> f${form}_results.txt
    cat tmp/f${form}_${tool}_ave.txt >> f${form}_results.txt
    sed -i '' -e '$a\' f${form}_results.txt
  done
done