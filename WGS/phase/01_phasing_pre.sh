sample= #list of offspring (20101,20203,5572,5814,M15S1,M15S2)
chr= #list of autosome
trio= #trio_family
ref= #reference genome

#Filtering for Mendelian Genetic Errors
mkdir ${sample}_Mendelian_error_filter
cd ${sample}_Mendelian_error_filter
vcftools --vcf final.${chr}.snp.filt.vcf --plink --out ${chr}
plink --file ${chr} --make-bed --out ${chr}
#Fill fam file with family information according to trio family
plink --bfile ${chr} --mendel --out ${chr}
sed '1d' ${chr}.mendel |awk '{print $4}' |sed "s/chr[0-9A-Z]*://g" > ${chr}.pos
awk '{print $1"\t"$2}' final.${chr}.snp.filt.vcf |grep -wf ${chr}.pos > ${chr}.mendel.quality
grep -vf ${chr}.mendel.quality final.${chr}.snp.filt.vcf > whatshapInput_${chr}.vcf

#generate phased vcf 
#father, mother, off from a trio family, sample corresponds to the id of the hybrids
whatshap phase --ped ${trio}.fam --reference=${ref} -o snp.${chr}.phased.vcf \
               whatshapInput_${chr}.vcf \
			   ${father}.sorted.add.markdup.bam \
			   ${mother}.sorted.add.markdup.bam \
			   ${off}.sorted.add.markdup.bam \
			   ${sample}.bam \
			   --chromosome ${chr}

#generate phased vcf of off, it is used for subsequent phasing of multi-omics data
grep -v "#" snp.${chr}.phased.vcf|awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\tGT\t"$12}' |awk -F ":" '{print $1}' |awk -v sample=$sample 'BEGIN{print "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t"sample }($10~/0\|1/)||($10~/1\|0/){print}' > pretag.${chr}.phased.vcf
sed -n '1,63p' snp.${chr}.phased.vcf > pretag.${chr}.head.txt
cat pretag.${chr}.head.txt pretag.${chr}.phased.vcf > pretag.${chr}.final.vcf
bgzip pretag.${chr}.final.vcf
tabix pretag.${chr}.final.vcf.gz
rm pretag.${chr}.phased.vcf pretag.${chr}.head.txt














