
# Generate Aerial vs Monpoly (need to change the generator.ml as well)
# for i in 5 10 15 20 25 45 60 90; do for j in `seq 1 10`; do ./generator.native -mtl -size $i > formulas/r${i}_${j}.formula; done; done
# for i in 5 10 15 20 25 45 60 90; do for j in `seq 1 10`; do ./convert_formulas.sh formulas/r${i}_${j}.formula > formulas/monpoly_r${i}_${j}.formula; done ; done

# Generate Aerial vs Montre (need to change the generator.ml as well)
for i in 5 10 15 20 25 45 60 90; 
do 
for j in `seq 1 10`; 
do 
fmas=$(./generator.native -mdl -size $i) 
f1=$(echo "$fmas" | cut -d "#" -f1)
f2=$(echo "$fmas" | cut -d "#" -f2)
echo "$f1" > formulas/r${i}_${j}.formula; 
echo "$f2" > formulas/montre_r${i}_100_${j}.formula; 
done;
done
# for i in 5 10 15 20 25 45 60 90; do for j in `seq 1 10`; do ./convert_formulas.sh formulas/next/r${i}_${j}.formula > formulas/next/monpoly_r${i}_${j}.formula; done ; done

#Generate interval formulas
# for i in 5 10 15 20 25 45 60 90; 
#  do 

#  d=$((i/2))
#  irate=$((1000*i))
#  drate=$((irate/2))

#  aef='! (p U[0,'${i}'] (q S['${d}','${i}'] r))' 
#  mpf='p () UNTIL [0, '${i}'] (q () SINCE ['${d}', '${i}'] r ())'
#  mof='(p*;(r;q*)%('${drate}','${irate}'))%(0,'${irate}')'

#  echo $aef  > formulas/r${i}.formula;
#  echo $mpf  > formulas/monpoly_r${i}.formula;
#  echo $mof  > formulas/montre_r${i}.formula;

#  done

