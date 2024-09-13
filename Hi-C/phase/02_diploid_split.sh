#!/bin/bash
#SBATCH -J ~1hdiploid_split
#SBATCH -N 1 -n 10
#SBATCH -e /home/gemeichenyu/log/diploid_split_job-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/diploid_split_job-%j_%a.log
#SBATCH -p all
#SBATCH --mem=50Gb
#SBATCH -a 1-13

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
juiceDir=/home/gemeichenyu/HiC
#############setting input and output directory##########

sample= #list of offspring(20101,20203,5572,5814,M15S1)
#INPUT=/home/guilu/

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
echo "Now We are working on ${tmpdir}/${Work_dir}!"
batch=`cat /home/tmpdir/Lichenyu/${sample}/name.txt|head -$PBS_ARRAYID | tail -1`
OUTPUT=/home/tmpdir/Lichenyu/${sample}/${batch}/aligned
cat ${OUTPUT}/${sample}_${batch}_diploid_chr1.txt ${OUTPUT}/${sample}_${batch}_diploid_chr10.txt ${OUTPUT}/${sample}_${batch}_diploid_chr11.txt ${OUTPUT}/${sample}_${batch}_diploid_chr12.txt ${OUTPUT}/${sample}_${batch}_diploid_chr13.txt ${OUTPUT}/${sample}_${batch}_diploid_chr14.txt ${OUTPUT}/${sample}_${batch}_diploid_chr15.txt ${OUTPUT}/${sample}_${batch}_diploid_chr16.txt ${OUTPUT}/${sample}_${batch}_diploid_chr17.txt ${OUTPUT}/${sample}_${batch}_diploid_chr18.txt ${OUTPUT}/${sample}_${batch}_diploid_chr2.txt ${OUTPUT}/${sample}_${batch}_diploid_chr3.txt ${OUTPUT}/${sample}_${batch}_diploid_chr4.txt ${OUTPUT}/${sample}_${batch}_diploid_chr5.txt ${OUTPUT}/${sample}_${batch}_diploid_chr6.txt ${OUTPUT}/${sample}_${batch}_diploid_chr7.txt ${OUTPUT}/${sample}_${batch}_diploid_chr8.txt ${OUTPUT}/${sample}_${batch}_diploid_chr9.txt ${OUTPUT}/${sample}_${batch}_diploid_chrX.txt > diploid.txt
awk -f ${juiceDir}/scripts/common/diploid_split.awk diploid.txt
sort -k2,2d -m maternal.txt maternal_both.txt | awk '{split($11,a,"/"); print a[1], $1,$2,$3,$4,$5,$6,$7,$8,"100","100"}' > mat.txt
sort -k2,2d -m paternal.txt paternal_both.txt | awk '{split($11,a,"/"); print a[1], $1,$2,$3,$4,$5,$6,$7,$8,"100","100"}' > pat.txt
#######CP BACK AND SAVE YOUR RESULTS #####################
cp mat.txt  ${OUTPUT}
cp pat.txt  ${OUTPUT}

######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
