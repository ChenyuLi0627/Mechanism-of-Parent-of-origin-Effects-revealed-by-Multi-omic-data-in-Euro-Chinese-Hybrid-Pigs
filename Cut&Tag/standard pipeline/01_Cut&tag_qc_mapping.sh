#!/bin/bash
#PBS -N Cut&tag mapping
#PBS -l nodes=1:ppn=20,mem=50gb
#PBS -e /home/Lichenyu/qsub_log 
#PBS -o /home/Lichenyu/qsub_log
#PBS -q cu
#PBS -t 8
# Kill script if any commands fail
set -e
echo "Job Start at `date`"

#Set input & final output path
#pacbio=/home/goldenpigs/0.data/1.pacbio/BMX
output=/home/Lichenyu/BF_Phased_cuttag/BF_H3K27ac_H3K4me3
#primer=/work/goldenpigs/1.HuangYZ/12.BMX
tmpdir=/tmpdisk  #892Gb
ref= #reference genome
#Get Number of running process
nprocs=`wc -l < $PBS_NODEFILE`
#Setup tempdisk for output
uid="Chenyuli" #user id
ls_date=`date +m%d%H%M%S` #Set Random date and time
Work_dir=${uid}_${ls_date}_${PBS_ARRAYID}  #temp directory
echo "the temprory directory is $tmpdir"
mkdir ${tmpdir}/${Work_dir}
cd ${tmpdir}/${Work_dir}

###############################################################################
##################                                                   ##########
##################     This is programming part                      ##########
##################                                                   ##########
##############################################################################
minQualityScore=2
inputfile=`cat /work/LCY_tmp/cuttag/unphase/name.txt |head -${PBS_ARRAYID}|tail -1`
name=`echo $inputfile|awk -F"/" '{print $NF}'`
echo ${name} "start....."
#QC
/home/Lichenyu/soft/fastp  -i ${inputfile}_1.fq.gz -o ${name}_QC_1.fq.gz -I ${inputfile}_2.fq.gz -O  ${name}_QC_2.fq.gz
mv fastp.html ${name}_fastp.html
mv fastp.json ${name}_fastp.json
#mapping to reference
/home/Lichenyu/soft/bowtie2-2.5.1-linux-x86_64/bowtie2  --end-to-end --very-sensitive --no-mixed --no-discordant -p 40 -x $ref  -1 ${name}_QC_1.fq.gz   -2 ${name}_QC_2.fq.gz -S ${name}.sam 2> ${name}_bowtie2.txt
rm *fq.gz
#deduplicate
singularity exec -B  ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir},/work/LCY_tmp:/work/LCY_tmp   /home/Singusoft/picard.sif java -jar /usr/local/bin/picard/picard.jar SortSam I=${name}.sam O=${name}_bowtie2.sorted.sam SORT_ORDER=coordinate
## mark duplicates
singularity exec -B  ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir},/work/LCY_tmp:/work/LCY_tmp   /home/Singusoft/picard.sif java -jar /usr/local/bin/picard/picard.jar MarkDuplicates I=${name}_bowtie2.sorted.sam O=${name}_bowtie2.sorted.dupMarked.sam METRICS_FILE=${name}_picard.dupMark.txt
## remove duplicates
singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir},/work/LCY_tmp:/work/LCY_tmp   /home/Singusoft/picard.sif java -jar /usr/local/bin/picard/picard.jar MarkDuplicates I=${name}_bowtie2.sorted.sam O=${name}_bowtie2.sorted.rmDup.sam REMOVE_DUPLICATES=true METRICS_FILE=${name}_picard.rmDup.txt
##fragmentLen
/home/Lichenyu/soft/samtools view -@30 -F 0x04 ${name}.sam | awk -F'\t' 'function abs(x){return ((x < 0.0) ? -x : x)} {print abs($9)}' | sort | uniq -c | awk -v OFS="\t" '{print $2, $1/2}' >${name}_fragmentLen.txt
##quality filter
/home/Lichenyu/soft/samtools view  -@30 -h -q $minQualityScore    ${name}_bowtie2.sorted.rmDup.sam >${name}_bowtie2.qualityScore${minQualityScore}.sam
##sam2bam
/home/Lichenyu/soft/samtools view -@30 -bS -F 0x04 ${name}_bowtie2.qualityScore${minQualityScore}.sam >${name}_bowtie2.mapped.bam
##bed
/home/Lichenyu/soft/bedtools bamtobed -i ${name}_bowtie2.mapped.bam -bedpe >${name}_bowtie2.bed
##bed filter
awk '$1==$4 && $6-$2 < 1000 {print $0}' ${name}_bowtie2.bed > ${name}_bowtie2.clean.bed
## Only extract the fragment related columns
cut -f 1,2,6 ${name}_bowtie2.clean.bed | sort -k1,1 -k2,2n -k3,3n  > ${name}_bowtie2.fragments.bed
##The genome was partitioned into 500 bp bins and the Pearson correlation of the log2-transformed values in each bin was calculated between replicate data sets
awk -v w=500 '{print $1, int(($2 + $3)/(2*w))*w + w/2}' ${name}_bowtie2.fragments.bed | sort -k1,1V -k2,2n | uniq -c | awk -v OFS="\t" '{print $2, $3, $1}' |  sort -k1,1V -k2,2n  >${name}_bowtie2.fragmentsCount.bin500.bed
rm *.sam *.bam
###############################################################################
##################                                                   ##########
##################     This is end of programming                    ##########
##################                                                   ##########
###############################################################################


#Copy my teminal files to output
cp * ${output}/.

#Attention, you must delete the temp directory before finished the Job!!!!
echo "Remove tmp files at ${Work_dir}"
cd ${output}
rm -rf ${tmpdir}/${Work_dir}


conda deactivate
#get time end the job
echo "Job finished at:" `date`
