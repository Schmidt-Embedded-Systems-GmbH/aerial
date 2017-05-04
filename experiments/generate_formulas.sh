for i in 5 10 15 20 25 50 75 100; do for j in `seq 1 10`; do ./generator.native -mtl -size $i > formulas/r${i}_${j}.formula; done; done
for i in 5 10 15 20 25 50 75 100; do for j in `seq 1 10`; do ./convert_formulas.sh formulas/r${i}_${j}.formula > formulas/monpoly_r${i}_${j}.formula; done ; done
