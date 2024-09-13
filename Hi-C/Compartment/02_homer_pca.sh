#!/bin/bash
#SBATCH -J 18H_homer_pca
#SBATCH -N 1 -c 40
#SBATCH -e /home/gemeichenyu/log/homer_pca-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/homer_pca-%j_%a.log
#SBATCH -p cu40
#SBATCH --mem=90Gb
#SBATCH -a 1-18

set -e

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


#############working directory setting###########
echo "Number of threads is $nprocs"

uid="lcy" #user id
ls_date=`date +m%d%H%M%S` #Set Random date and time
Work_dir=${uid}_${ls_date}_${PBS_ARRAYID}  #
cd ${tmpdir}
echo "the temporary directory is $tmpdir"
mkdir -p ${Work_dir}
echo "Job started at:" `date`
cd ${tmpdir}/${Work_dir}
echo "Now We are working on ${tmpdir}/${Work_dir}!"
echo `hostname`
##################################################################
########## YOUR RUNNING SCRIPTS                      #############
##################################################################
sample= #list of offspring(20101,20203,5572,5814,M15S1)
chr=`cat /home/gemeichenyu/pca/chr.txt|head -${PBS_ARRAYID}|tail -1`
input=/home/gemeichenyu/pca
output=/home/gemeichenyu/pca/output
ref=/home/gemeichenyu/ref/DRC_BWA/DRC.MotherHap.fa

zcat ${sample}_merged_nodups.txt.gz| awk '{print $2"\t"$3"\t"$1"\t"$6"\t"$7"\t"$5}'|sed 's/\<0\>/\+/g;s/\<16\>/\-/g'|cat -n -|awk -v I=$chr '{if($2==I && $5==I)print $0}' > 5814_${chr}.homer
singularity exec miniconda_homer_R.sif makeTagDirectory ${sample}_${chr} -format HiCsummary ${tmpdir}/${Work_dir}/${sample}_${chr}.homer
singularity exec miniconda_homer_R.sif runHiCpca.pl \
        		${sample}_${chr}_100k \
        		${tmpdir}/${Work_dir}/${sample}_${chr}\
        		-cpu 40 \
        		-res 100000 \
        		-genome DRC \
        		-pc 1


#########CP BACK AND SAVE YOUR RESULTS #####################

cp ./*PC1* ${output}/

######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
