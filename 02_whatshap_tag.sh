#!/bin/bash
#PBS -N whatshap
#PBS -l nodes=1:ppn=20,mem=50gb
#PBS -e /home/Lichenyu/qsub_log 
#PBS -o /home/Lichenyu/qsub_log
#PBS -q cu
#PBS -t 18
# Kill script if any commands fail
set -e
echo "Job Start at `date`"

#Set input & final output path
#pacbio=/home/goldenpigs/0.data/1.pacbio/BMX
input=/work/LCY_tmp/RNAseq/unphased
output=/work/LCY_tmp/RNAseq/phased
#primer=/work/goldenpigs/1.HuangYZ/12.BMX
tmpdir=/tmpdisk  #892Gb

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
inputfile=`cat ${input}/sample.txt|head -${PBS_ARRAYID}|tail -1`
echo "$inputfile" |sed 's/.sorted.bam//' |awk -F/ '{print $NF}'
sample_name=`echo "$inputfile" | sed 's/.sorted.bam//' |awk -F/ '{print $NF}'`
sample=`echo $sample_name |awk -F "_" '{print $2}'`
singularity exec  -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir},/work/LCY_tmp:/work/LCY_tmp    /home/Singusoft/8.whatshap.sif whatshap haplotag -o ${sample_name}.RNA.sorted.rg.whatshaptag.bam --reference /home/Lichenyu/ref/DRC/DRC.MotherHap.fa  /work/LCY_tmp/VCF/${sample}/${sample}_pretag.phased.vcf.gz  ${input}/${sample_name}_sorted_add.bam
~/soft/samtools view -@ 20 -H ${sample_name}.RNA.sorted.rg.whatshaptag.bam > ${sample_name}_head.txt
~/soft/samtools view -@ 20 ${sample_name}.RNA.sorted.rg.whatshaptag.bam | grep  "HP:i:1" > ${sample_name}.RNA.sorted.rg.whatshaptag_H1.sam
~/soft/samtools view -@ 20 ${sample_name}.RNA.sorted.rg.whatshaptag.bam | grep  "HP:i:2" > ${sample_name}.RNA.sorted.rg.whatshaptag_H2.sam
cat ${sample_name}_head.txt ${sample_name}.RNA.sorted.rg.whatshaptag_H1.sam > ${sample_name}.RNA_H1.sam
cat ${sample_name}_head.txt ${sample_name}.RNA.sorted.rg.whatshaptag_H2.sam > ${sample_name}.RNA_H2.sam
~/soft/samtools view -bS -@ 10 ${sample_name}.RNA_H1.sam > ${sample_name}.RNA_H1.bam
~/soft/samtools view -bS -@ 10 ${sample_name}.RNA_H2.sam > ${sample_name}.RNA_H2.bam
###############################################################################
##################                                                   ##########
##################     This is end of programming                    ##########
##################                                                   ##########
###############################################################################


#Copy my teminal files to output
cp *RNA_H*.bam ${output}/.

#Attention, you must delete the temp directory before finished the Job!!!!
echo "Remove tmp files at ${Work_dir}"
cd ${output}
rm -rf ${tmpdir}/${Work_dir}


conda deactivate
#get time end the job
echo "Job finished at:" `date`
