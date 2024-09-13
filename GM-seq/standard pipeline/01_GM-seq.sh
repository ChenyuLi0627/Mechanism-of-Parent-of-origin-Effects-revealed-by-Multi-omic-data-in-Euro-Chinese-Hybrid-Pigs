R1= 
R2=
bwa_index=
threads=
sample= #list of offspring (20101,20203,5572,5814,M15S1,M15S2)
tissue=  #BF/LD

#mapping
bwa mem -t $threads $bwa_index  $R1 $R2|samtools view -Sb > ${sample}_${tissue}.bam
#sort
samtools sort -@$threads -T ${sample} -m2G -O bam -o ${sample}_${tissue}_sort.bam  ${sample}_${tissue}.bam
#mark PCR dup
sambamba markdup  -t 10  ${sample}_${tissue}_sort.bam  ${sample}_${tissue}_sort_markdup.bam
#extracted samples,positove control,negative control mapping files, respectively
samtools view -@10 ${sample}_${tissue}_sort_markdup.bam|awk '{if($3~/chr/){print $0 >> "chr.sam"}else if($3~/sequence/){print $0 >> "Positive.sam"}else if($3=="L"){print $0 >> "Negative.sam"}}' 

#Adds header information
bam=   #the mappping file for the sample containg BF/LD tissue
mv chr.sam ${sample}_${tissue}_tmp.sam
samtools view -H $bam > ${sample}_${tissue}.head.txt 
cat ${sample}_${tissue}.head.txt ${sample}_${tissue}_tmp.sam > ${sample}_${tissue}_tmp.head.sam
samtools view -@20 -bS ${sample}_${tissue}_tmp.head.sam > ${sample}_${tissue}_final.bam 
rm ${sample}_${tissue}.head.txt ${sample}_${tissue}_tmp.*sam

#identify CpG site
bam=  #the mappping file for the sample (BF/LD) containing the header
ref=  #your reference
astair call -i ${bam} -f ${ref} -m mCtoT \
            --skip_clip_overlap False --minimum_base_quality 20 \
			--minimum_mapping_quality 10 --ignore_orphans True \
			--max_depth 10000 --start_clip 0 --end_clip 5 \
			--context CpG -d ./callmethyl/ -t 36 


















