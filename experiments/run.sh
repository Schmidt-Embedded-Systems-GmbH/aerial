source ./functions.sh

TTO=$(bc -l <<< "scale=3; ${TO}/1000")
TIMEOUT="$TIMEOUT ${TTO}s"
AERIAL=$(which aerial)
MONPOLY=$(which monpoly)
MONTRE=$(which montre)

tool=$1   #Tool name
logdir=$2 #type of log (custom, random, constant, monpoly)
rate=$3   #event rate of the trace
form=$4   #Formula index 
trace=$4  #formula specific trace (makes sense only for custom and monpoly logs)
iform=$5  #formula index
i=$6      #trace index
test=$7   #type of experiment (rate, formula, interval)

#optional aerial params
if [ ! -z "$8" ] # language (mtl or mdl)
then
    lang="$8"
else 
    lang="mdl"
fi

if [ ! -z "$9" ] # mode (naive, local, global)
then
    mode="$9"
else
    mode="global"
fi

if [ ! -z "${10}" ] # representation (expr, bdd, safa)
then
    repr="${10}"
else
    repr="expr"
fi

#remove formula specific trace parameter 
if [[ "$logdir" == "constant" || "$logdir" == "random" ]]
then
  trace="1"
fi

#prepare to run different tools
case "$tool" in
  AERIAL|Aerial|aerial ) 
    modestr="${tool}_${lang}_${mode}_${repr}"
    CMD="$AERIAL -$lang -mode $mode -$repr -fmla formulas/${test}/f${form}_${iform}.formula -log logs/${logdir}/tr${trace}_${i}_${rate}.log -out /dev/null 2>&1"
  ;;
  MONPOLY|Monpoly|monpoly )
    modestr="${tool}"
    CMD="$MONPOLY -sig formulas/f.sig -formula formulas/${test}/monpoly_f${form}_${iform}.formula -log logs/${logdir}/tr${trace}_${i}_${rate}.log 2>&1 >/dev/null"
  ;;
  MONTRE|Montre|montre ) 
    modestr="${tool}"
    CMD="$MONTRE -i -e '`cat formulas/${test}/montre_f${form}_${rate}_${iform}.formula`' -o /dev/null 'logs/${logdir}/montre_tr${trace}_${i}_${rate}.log' 2>&1 > /dev/null "
  ;;
  * ) echo "Invalid tool!"; exit -1 ;;
esac

#check for disqualification
rc=$(./disq.sh $test $modestr $rate $form)
if [[ "$rc" = "" ]] ; then
    echo "$modestr, $rate, $form, $i, disq, disq"
    exit -1
fi

#combine trace and formula index
index=$((i-1))
index=$((index*MAXIDX))
index=$((index+iform))

#run the tools
# tmpfile="tmp/TO${modestr}_${rate}_${form}.tmp"
params="$modestr, $rate, $form, $index"

#DEBUG
#echo "$params Started..."

run "$CMD" "$params" "$rc"

#DEBUG
#echo "$CMD"

