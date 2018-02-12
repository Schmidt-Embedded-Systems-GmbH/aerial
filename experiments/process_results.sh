#!/bin/bash

source ./functions.sh

t=$1
l=$2


#average and std
cat results-${t}-${l}.csv | grep -v Time | grep -v disq | sed "s/(timeout)//g" | gawk -F "," '
{
n[$1][$2][$3]++;
dm[$1][$2][$3]=$5/1024/1024-m[$1][$2][$3];
dt[$1][$2][$3]=$6-t[$1][$2][$3];
m[$1][$2][$3]+=dm[$1][$2][$3] / n[$1][$2][$3];
t[$1][$2][$3]+=dt[$1][$2][$3] / n[$1][$2][$3];
dm2[$1][$2][$3]=$5/1024/1024-m[$1][$2][$3];
dt2[$1][$2][$3]=$6-t[$1][$2][$3];
m2m[$1][$2][$3]=dm[$1][$2][$3]*dm2[$1][$2][$3];
m2t[$1][$2][$3]=dt[$1][$2][$3]*dt2[$1][$2][$3];
}
END{
for(i in t){
      for(j in t[i]){
      	    for(k in t[i][j]){
	    print i ", "j ", "k ", "m[i][j][k] ", "sqrt(m2m[i][j][k]/(n[i][j][k]-1)) ", "t[i][j][k] ", "sqrt(m2t[i][j][k]/(n[i][j][k]-1)) 
	    }}}
}' >> results-${t}-${l}-avg.csv

echo "Tool, Rate, Formula, Space, Sdev, Time, Tdev" 
cat results-${t}-${l}-avg.csv | sort -n -k 2 -t "," 

rm results-${t}-${l}-avg.csv