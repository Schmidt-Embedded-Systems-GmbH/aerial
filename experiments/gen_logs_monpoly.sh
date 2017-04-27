#!/bin/bash

function get_rate {
    # convert rates 100 -> 140
    #               500 -> 688 
    #               1000 -> 1395
    #               3000 -> 4180
    #               5000 -> 7020
    #               10000 -> 14000
    #               30000 -> 42000
    #               50000 -> 
    #               100000 -> 
   if [ "$1" -eq "100" ]
   then
     echo "140"
   elif [ "$1" -eq "500" ]
   then
     echo "688"
   elif [ "$1" -eq "1000" ]
   then
     echo "1395"
   elif [ "$1" -eq "3000" ]
   then
     echo "4180"
   elif [ "$1" -eq "5000" ]
   then
     echo "7020"
   elif [ "$1" -eq "10000" ]
   then
     echo "14000"
   elif [ "$1" -eq "30000" ]
   then
     echo "42000"
   elif [ "$1" -eq "50000" ]
   then
     echo "70300"
   else
     echo "140300"
   fi
}

rate=$1
form=$2
i=$3

logdir="logs/monpoly"

mkdir -p $logdir

ocamlbuild gen_log.native

#monpoly generator
mrate=$(get_rate $rate)
./gen_log.native -time_span 100 -event_rate $mrate -seed_index $i -policy P$form | sed -n '/\@101/q;p' 2> /dev/null > $logdir/tr${form}_${i}_${rate}.log
echo "generated log ${i} for formula ${form} with rate ${rate} using the monpoly generator";


#./convert_logs.sh $logdir/tr${form}_${i}_${rate}.log > $logdir/montre_tr${form}_${i}_${rate}.log
