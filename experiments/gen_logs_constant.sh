rate=$1
form=$2
i=$3
MAXTS=100


function get_events {
    # get constants 1 -> ""
    #               2 -> "p ()"
    #               3 -> "q ()"
    #               4 -> "r ()"
    #               5 -> "p () q ()"
    #               6 -> "q () r ()"
    #               7 -> "p () r ()"
    #               8 -> "p () q () r ()"
   if [ "$1" -eq "1" ]
   then
     echo ""
   elif [ "$1" -eq "2" ]
   then
     echo "p ()"
   elif [ "$1" -eq "3" ]
   then
     echo "q ()"
   elif [ "$1" -eq "4" ]
   then
     echo "r ()"
   elif [ "$1" -eq "5" ]
   then
     echo "p () q ()"
   elif [ "$1" -eq "6" ]
   then
     echo "q () r ()"
   elif [ "$1" -eq "7" ]
   then
     echo "p () r ()"
   else
     echo "p () q () r ()"
   fi
}

logdir="logs/constant"
mkdir -p $logdir

const=$(get_events $i)

for ts in `seq 1 $MAXTS`; do for j in `seq 1 $rate`; do echo "@$ts $const"; done; done > $logdir/tr${form}_${i}_${rate}.log

#converting to montre format
./convert_logs.sh $logdir/tr${form}_${i}_${rate}.log $rate > $logdir/montre_tr${form}_${i}_${rate}.log
