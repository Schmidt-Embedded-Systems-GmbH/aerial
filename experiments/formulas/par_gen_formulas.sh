#!/bin/bash
source ../params.cfg

if [ ! -z "$1" ]
then
TEST=$1
fi


function gen_rate {

    mkdir -p rate

    for idx in $RFIDX;
    do

        f1='! (true U[0,5] q)'
        f2='! (p U[0,5] q)'
        f3='! (p U[0,5] (q S[2,6] r))'
        f4='! (p U[0,5] (q U[2,6] r))'

        mf1='TRUE UNTIL [0, 5] q ()'
        mf2='p () UNTIL [0, 5] q ()'
        mf3='p () UNTIL [0, 5] (q () SINCE [2, 6] r ())'
        mf4='p () UNTIL [0, 5] (q () UNTIL [2, 6] r ())'

        echo $f1 > rate/f1_${idx}.formula
        echo $f2 > rate/f2_${idx}.formula
        echo $f3 > rate/f3_${idx}.formula
        echo $f4 > rate/f4_${idx}.formula
        echo $mf1 > rate/monpoly_f1_${idx}.formula
        echo $mf2 > rate/monpoly_f2_${idx}.formula
        echo $mf3 > rate/monpoly_f3_${idx}.formula
        echo $mf4 > rate/monpoly_f4_${idx}.formula


        for rate in $RATES;
        do       
            #scale montre intervals to the event rate
            frate=$((rate*5*2))
            srate=$((rate*6*2))
            trate=$((rate*2*2))

            mof1='((!q||q)*;q)%(0,'${frate}')'
            mof2='(p*;q)%(0,'${frate}')'
            mof3='(p*;(r;q*)%('${trate}','${srate}'))%(0,'${frate}')'
            mof4='(p*;(q*;r)%('${trate}','${srate}'))%(0,'${frate}')'

            echo $mof1 > rate/montre_f1_${rate}_${idx}.formula
            echo $mof2 > rate/montre_f2_${rate}_${idx}.formula
            echo $mof3 > rate/montre_f3_${rate}_${idx}.formula
            echo $mof4 > rate/montre_f4_${rate}_${idx}.formula 
        done
    done

}

function gen_formula {
    local t=$1
    mkdir -p formula
    ./gen_formulas.sh "-$LANG"
}

function gen_interval {
    #Generate interval formulas
    mkdir -p interval
    for i in $INTERVALS; 
    do 
        for idx in $IFIDX;
        do
            d=$((i/2))
            irate=$(($IRATES*i))
            drate=$((irate/2))

            aef='! (p U[0,'${i}'] (q S['${d}','${i}'] r))' 
            mpf='p () UNTIL [0, '${i}'] (q () SINCE ['${d}', '${i}'] r ())'
            mof='(p*;(r;q*)%('${drate}','${irate}'))%(0,'${irate}')'

            echo $aef  > interval/f${i}_${idx}.formula;
            echo $mpf  > interval/monpoly_f${i}_${idx}.formula;
            echo $mof  > interval/montre_f${i}_${IRATES}_${idx}.formula;
        done

    done
}


for t in $TEST; do

    if [ "$t" == "rate" ]
    then
        gen_rate 
    elif [ "$t" == "formula" ]
    then 
        gen_formula 
    elif [ "$t" == "interval" ]
    then
        gen_interval 
    else
    echo "Unknown experiment type"  
    fi
done