rate=$1
form=$2
i=$3
MAXTS=100

logdir="logs/random"
mkdir -p $logdir


for ts in `seq 1 $MAXTS`; do for j in `seq 1 $rate`; do [[ $((RANDOM % 2)) = 0 ]] && p="p () " || p=""; [[ $((RANDOM % 2)) = 0 ]] && q="q () " || q=""; [[ $((RANDOM % 2)) = 0 ]] && r="r () " || r=""; echo "@$ts $p$q$r"; done; done > $logdir/tr${form}_${i}_${rate}.log

#converting to montre format
./convert_logs.sh $logdir/tr${form}_${i}_${rate}.log $rate > $logdir/montre_tr${form}_${i}_${rate}.log
