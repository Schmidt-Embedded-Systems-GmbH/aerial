type=$1

for i in 5 10 15 20 25 45 60 90; 
do 
for j in `seq 1 10`; 
do 
fmas=$(./generator.native -$type -size $i)
f1=$(echo "$fmas" | cut -d "#" -f1)
f2=$(echo "$fmas" | cut -d "#" -f2)
echo "$f1" > formulas/r${i}_${j}.formula; 
echo "$f2" > formulas/montre_r${i}_100_${j}.formula; 
done;
done

if [ "$type" == "mtl" ]
then
for i in 5 10 15 20 25 45 60 90; 
do 
for j in `seq 1 10`; 
do 
./convert_formulas.sh formulas/r${i}_${j}.formula > formulas/monpoly_r${i}_${j}.formula; 
done; 
done

fi

