ref= #reference genome
name= #list of parent and offspring (DD20400115,52904,20101,DD20400143,66208,20203,9705,862,5572,3905,3230,5814,B8861,M15,M15S1,M15S2)
chr= #list of autosome
sample= #list of offspring (20101,20203,5572,5814,M15S1,M15S2)

#short-reads WGS
#QC
fastp -l 100 -i ${name}_1.fq.gz -o ${name}_1.clean.fq.gz -I ${name}_2.fq.gz -O ${name}_2.clean.fq.gz
#Mapping
bwa mem -t 40 ${ref} ${name}_1.clean.fq.gz ${name}_2.clean.fq.gz |samtools view -Sb > ${name}.bam
#sort
samtools sort -@ 10 -T ${name} -m2G -O bam -o ${name}.sorted.bam  ${name}.bam

#gatk pipeline
gatk AddOrReplaceReadGroups -I ${name}.sorted.bam -O ${name}.sorted.add.bam -ID $name -LB library1 -PL illumina -SM $name -PU unit1 &&
gatk MarkDuplicates -I ${name}.sorted.add.bam -O ${name}.sorted.add.markdup.bam -M ${name}.sorted.add.markdup_metrics.txt &&
samtools index ${name}.sorted.add.markdup.bam
gatk HaplotypeCaller -R ${ref} --emit-ref-confidence GVCF -I ${name}.sorted.add.markdup.bam -O ${name}.sorted.add.${chr}.markdup.g.vcf -L ${chr}
#name indicates the ids of father, mother, and off 
gatk CombineGVCFs -R ${ref} --variant ${father}.sorted.add.${chr}.markdup.g.vcf --variant ${mother}.sorted.add.${chr}.markdup.g.vcf --variant ${off}.sorted.add.${chr}.markdup.g.vcf -O merge.${chr}.g.vcf
gatk GenotypeGVCFs -R ${ref} -V merge.${chr}.g.vcf -O merge.${chr}.vcf
bgzip merge.${chr}.vcf
tabix -p vcf  merge.${chr}.vcf.gz
gatk SelectVariants -V merge.${chr}.vcf.gz -O merge.${chr}.snp.vcf --select-type-to-include SNP
gatk VariantFiltration -O merge.${chr}.vcf.temp -V merge.${chr}.snp.vcf --filter-expression 'QUAL < 30.0 || QD < 2.0 || FS > 60.0 ||  SOR > 4.0' --filter-name lowQualFilter --cluster-window-size 10 --cluster-size 3 --missing-values-evaluate-as-failing
grep PASS merge.${chr}.vcf.temp > merge.${chr}.snp.filt.vcf

#filter
awk '{if(length($4)==1&&length($5)==1) print $0}' merge.${chr}.snp.filt.vcf > one.${chr}.snp.filt.vcf
grep "^#" merge.${chr}.vcf.temp > head.${chr}.vcf.temp
cat head.${chr}.vcf.temp one.${chr}.snp.filt.vcf > final.${chr}.snp.filt.vcf
rm one.${chr}.snp.filt.vcf head.${chr}.vcf.temp


#long-reads WGS
minimap2 -ax map-ont ${ref} ${sample}.fq > output.sam 
samtools view -Sb output.sam > output_unsorted.bam 
samtools sort output_unsorted.bam -o ${sample}.bam
samtools index ${sample}.bam
