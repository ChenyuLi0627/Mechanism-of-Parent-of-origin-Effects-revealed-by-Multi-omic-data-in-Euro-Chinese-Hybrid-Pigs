#!/bin/bash
#SBATCH -J ~1D_juicer
#SBATCH -N 1 -n 80
#SBATCH -e /home/gemeichenyu/log/phase-prejob-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/phase-prejob-%j_%a.log
#SBATCH -p all
#SBATCH --mem=150Gb
#SBATCH -a 7

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

juicer=/home/gemeichenyu/soft/juicer-1.6/CPU/juicer_mod.sh

#############setting input and output directory##########
OUTPUT=/home/gemeichenyu/HiC/work


#############working directory setting###########
uid="lcy" #user id
ls_date=`date +m%d%H%M%S` #Set Random date and time
Work_dir=${uid}_${ls_date}_${PBS_ARRAYID}  #
cd ${tmpdir}
echo "the temporary directory is $tmpdir"
mkdir -p ${Work_dir}
echo "Job started at:" `date`
sample= #list of oddspring
ref= #reference genome
ref_size= #size of reference genome
#####copy data to node computers ###################

##################################################################
########## YOUR RUNNING SCRIPTS                      #############
##################################################################
cd ${tmpdir}/${Work_dir}
echo "Now We are working on ${tmpdir}/${Work_dir}!"
inputfile=`cat /home/gemeichenyu/HiC/library.txt|head -$PBS_ARRAYID | tail -1`   ## The name list of libraries for each sample (eg. L1-L13)
$juicer -z $ref -p $ref_size -y MboI.txt -d /home/tmpdir/Lichenyu/${sample}/${inputfile}  -D /home/gemeichenyu/HiC  -t 80  -s MboI -S early


#########CP BACK AND SAVE YOUR RESULTS #####################
cp * ${OUTPUT}

######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
