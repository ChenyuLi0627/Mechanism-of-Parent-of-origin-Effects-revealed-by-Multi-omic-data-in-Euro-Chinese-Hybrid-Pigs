#DMR selection
sample= #list of offspring (20101,20203,5572,5814,M15S1,M15S2)
group1=  #CpG site methylation levels of the paternal phase of the hybrids
group2=  #CpG site methylation levels of the maternal phase of the hybrids
tissue= #BF/LD
metilene_input.pl --in1 ${group1} --in2 ${group2} --h1 H1 --h2 H2 --out ${sample}_${tissue}.input

#screened DMR 
for i in `cat input.txt` ##The list of ${sample}_${tissue}.input
do
name=$(echo "$i" | awk -F "/" '{print $NF}' | sed 's/_manu_H1_H2.input//g')    
##DMC  
sed '1d' "$i" | awk '{print $1"\t"$2-1"\t"$2"\t"$3-$4}' | awk '($NF>0.3||$NF< -0.3){print }' > "${name}_manu_H1_H2.DMC"  
##DMR obtained by interval expansion of DMC   
Rscript DMR.r "${name}_manu_H1_H2.DMC" "$name"  
awk '{print $1"\t"$2"\t"$4}' "${name}_DMR.txt" > "${name}_DMR.bed"  
##Ensure that 80% of the DMCs within each DMR have the same direction  
bedtools intersect -a "${name}_manu_H1_H2.DMC" -b "${name}_DMR.bed" -wa -wb | awk '{  
    if($4>0){print $5"\t"$6"\t"$7"\t1\t1"}  
    else{print $5"\t"$6"\t"$7"\t-1\t1"}  
}' | awk '{  
    a[$1"\t"$2"\t"$3]+=$4; b[$1"\t"$2"\t"$3]+=$5  
} END {  
    for(i in a) {  
        if (abs($4) > $5 * 0.8) {  
            if ($NF >= 3) {  
                print i"\t"a[i]"\t"b[i]  
            }  
        }  
    }  
}' > "${name}_DMR_selected.bed"  
##The average of the selected DMRs
bedtools intersect -b "${name}_DMR_selected.bed" -a "${name}_manu_H1_H2.DMC" -wa -wb | awk '{  
    print $0"\t1"  
}' | awk '{  
    a[$5"\t"$6"\t"$7]+=$4; b[$5"\t"$6"\t"$7]+=$NF  
} END {  
    for(i in a) {  
        print i"\t"a[i]/b[i]  
    }  
}' | sort -k1,1V -k2,2n > "${name}_DMR_selected.mean"
done