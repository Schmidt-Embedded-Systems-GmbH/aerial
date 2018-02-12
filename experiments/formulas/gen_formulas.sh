#!/bin/bash
source ../params.cfg

type=$1

make -C ../../ generate

for i in $FORMS; do 
    for j in `seq 1 $MAXFIDX`; do 
        fmas=$(./generator_main.native $type -size $i -rate $RATES)
        f=$(echo "$fmas" | cut -d "#" -f1)
        echo "$f" > formula/f${i}_${j}.formula; 
        idx=2
        for r in $RATES; do
            f=$(echo "$fmas" | cut -d "#" -f$idx)
            idx=$((idx+1))
            echo "$f" > formula/montre_f${i}_${r}_${j}.formula; 
        done
        if [ "$type" == "-mtl" ]; then
            ./convert_formulas.sh formula/f${i}_${j}.formula > formula/monpoly_f${i}_${j}.formula; 
        fi
    done
done

