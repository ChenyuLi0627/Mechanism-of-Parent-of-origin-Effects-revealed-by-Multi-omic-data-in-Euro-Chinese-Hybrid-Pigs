#!/bin/bash
#SBATCH -J whatshap
#SBATCH -N 1 -n 10
#SBATCH -e /home/gemeichenyu/log/phase-prejob-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/phase-prejob-%j_%a.log
#SBATCH -p all
#SBATCH --mem=30Gb
#SBATCH -a 3

echo "Job Start at `date`"
#####enviroments setting
PBS_ARRAYID=${SLURM_ARRAY_TASK_ID}
array_jobid=${SLURM_ARRAY_JOB_ID}
jobid=${SLURM_JOB_ID}
job_name=${SLURM_JOB_NAME}
workdir=${SLURM_SUBMIT_DIR}
pid=${SLURM_TASK_PID}
nprocs=${SLURM_JOB_CPUS_PER_NODE}
tmpdir=/tmpdisk

echo "Number of threads is $nprocs"

##########software path setting#############

juicer=/home/gemeichenyu/soft/juicer-1.6/CPU/juicer-phase-pre.sh

#############setting input and output directory##########
output=/home/gemeichenyu/transfer/cuttag/bin_coverage
input=/home/gemeichenyu/transfer/cuttag/bin_coverage

#############working directory setting###########
uid="lcy" #user id
ls_date=`date +m%d%H%M%S` #Set Random date and time
Work_dir=${uid}_${ls_date}_${PBS_ARRAYID}  #
cd ${tmpdir}
echo "the temporary directory is $tmpdir"
mkdir -p ${Work_dir}
echo "Job started at:" `date`

#####copy data to node computers ###################

##################################################################
########## YOUR RUNNING SCRIPTS                      #############
##################################################################
cd ${tmpdir}/${Work_dir}


inputfile=`cat ${input}/sample.txt|head -${PBS_ARRAYID}|tail -1`
echo "$inputfile" |sed 's/_bowtie2.mapped.bam//' |awk -F/ '{print $NF}'
sample_name=`echo "$inputfile" | sed 's/_bowtie2.mapped.bam//' |awk -F/ '{print $NF}'`
sample=`echo $sample_name |awk -F "_" '{print $1}'`
singularity exec  -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir} /home/guilu/software/8.whatshap.sif  whatshap haplotag -o ${sample_name}.sorted.rg.whatshaptag.bam --reference /home/gemeichenyu/ref/DRC_BWA/DRC.MotherHap.fa  ${input}/VCF/${sample}/${sample}_pretag.phased.vcf.gz  ${input}/${sample_name}_sorted_add.bam
~/soft/samtools1.9/bin/samtools view -@ 20 -H ${sample_name}.sorted.rg.whatshaptag.bam > ${sample_name}_head.txt
~/soft/samtools1.9/bin/samtools view -@ 20 ${sample_name}.sorted.rg.whatshaptag.bam | grep  "HP:i:1" > ${sample_name}.sorted.rg.whatshaptag_H1.sam
~/soft/samtools1.9/bin/samtools view -@ 20 ${sample_name}.sorted.rg.whatshaptag.bam | grep  "HP:i:2" > ${sample_name}.sorted.rg.whatshaptag_H2.sam
cat ${sample_name}_head.txt ${sample_name}.sorted.rg.whatshaptag_H1.sam > ${sample_name}.H1.sam
cat ${sample_name}_head.txt ${sample_name}.sorted.rg.whatshaptag_H2.sam > ${sample_name}.H2.sam
~/soft/samtools1.9/bin/samtools view -bS -@ 10 ${sample_name}.H1.sam > ${sample_name}.H1.bam
~/soft/samtools1.9/bin/samtools view -bS -@ 10 ${sample_name}.H2.sam > ${sample_name}.H2.bam

#########CP BACK AND SAVE YOUR RESULTS #####################
cp *H*.bam ${output}

######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
