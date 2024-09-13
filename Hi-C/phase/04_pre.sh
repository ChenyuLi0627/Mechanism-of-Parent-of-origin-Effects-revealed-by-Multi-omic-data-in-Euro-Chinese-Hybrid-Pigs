#!/bin/bash
#SBATCH -J ~4hdiploid_pre
#SBATCH -N 1 -n 30
#SBATCH -e /home/gemeichenyu/log/diploid_pre-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/diploid_pre-%j_%a.log
#SBATCH -p all
#SBATCH --mem=100Gb
#SBATCH -a  10

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
parent=pat
OUTPUT=/home/tmpdir/Lichenyu/${sample}
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
chr=`cat /home/tmpdir/Lichenyu/${sample}/chr.txt|head -$PBS_ARRAYID | tail -1`
if [ $parent == pat ]
then
awk -v chr=$chr '($2==chr){print }'  ${OUTPUT}/pat.txt > ${chr}_pat.txt
~/soft/juicer/CPU/common/juicer_tools pre ${chr}_pat.txt  -r 100000,20000,10000,5000 ${chr}_paternal.hic  ~/HiC/restriction_sites/DRC.MotherHap.fa.size   
else
awk -v chr=$chr '($2==chr){print }'  ${OUTPUT}/mat.txt > ${chr}_mat.txt
~/soft/juicer/CPU/common/juicer_tools pre ${chr}_mat.txt  -r 100000,20000,10000,5000 ${chr}_maternal.hic  ~/HiC/restriction_sites/DRC.MotherHap.fa.size
fi
#######CP BACK AND SAVE YOUR RESULTS #####################
cp *hic  ${OUTPUT}

######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
