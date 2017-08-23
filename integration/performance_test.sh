#parameters
MAXIDX=`cat maxidx`
type=$1
offset=$2
db=$3

if [ -z "$db" ]
then
    echo "Detecting logs and formulas..."
    #...
else
    echo "Generating logs..."
    # traces
    rm -rf logs
    mkdir -p logs
    parallel ../experiments/gen_logs_random.sh  ::: `cat rates` ::: 2 ::: `seq 1 $MAXIDX`  ::: 10 2> /dev/null

    echo "Generating formulas..."
    # formulas
    rm -rf formulas
    mkdir -p formulas
    echo "   Compiling the formula generator..."
    make -C ../ generate
    for i in `cat forms`;
    do
    for j in `seq 1 $MAXIDX`;
    do
    fmas=$(./generator_main.native -$type -size $i)
    f1=$(echo "$fmas" | cut -d "#" -f1)
    echo "$f1" > formulas/r${i}_${j}.formula;
    done;
    done

fi

echo "Performance tests (this will take a while)..."
# monitring
#Script for random formulas
echo "Formula, FID, Rate, LID, Space, Time" > results.csv
parallel ./aerial.sh ::: `cat rates` ::: `cat forms` ::: `seq 1 $MAXIDX` ::: `seq 1 $MAXIDX` ::: $type ::: $offset >> results.csv


echo "Aggregating results..."
#average, std, min, and max
echo "Formula, Rate, Space, Sdev, Smin, Smax, Time, Tdev, Tmin, Tmax" > results-avg.csv
cat results.csv | grep -v Time | gawk -F "," '
{
n[$1][$2]++;
dm[$1][$2]=$5-m[$1][$2];
dt[$1][$2]=$6-t[$1][$2];
m[$1][$2]+=dm[$1][$2] / n[$1][$2];
t[$1][$2]+=dt[$1][$2] / n[$1][$2];
dm2[$1][$2]=$5-m[$1][$2];
dt2[$1][$2]=$6-t[$1][$2];
m2m[$1][$2]=dm[$1][$2]*dm2[$1][$2];
m2t[$1][$2]=dt[$1][$2]*dt2[$1][$2];

if (!( ($1 in mmin) && ($2 in mmin[$1]))) mmin[$1][$2]=$5
if (!( ($1 in tmin) && ($2 in tmin[$1]))) tmin[$1][$2]=$6

if ($5<mmin[$1][$2]) mmin[$1][$2]=$5;
if ($5>mmax[$1][$2]) mmax[$1][$2]=$5;
if ($6<tmin[$1][$2]) tmin[$1][$2]=$6;
if ($6>tmax[$1][$2]) tmax[$1][$2]=$6;
}
END{
for(i in t){
      for(j in t[i]){
	    print i ","j ", "m[i][j] ", "sqrt(m2m[i][j]/(n[i][j]-1)) ","mmin[i][j] ","mmax[i][j] ", "t[i][j] ", "sqrt(m2t[i][j]/(n[i][j]-1)) ","tmin[i][j] ","tmax[i][j]
	    }}
}' >> results-avg.csv


echo "Done."