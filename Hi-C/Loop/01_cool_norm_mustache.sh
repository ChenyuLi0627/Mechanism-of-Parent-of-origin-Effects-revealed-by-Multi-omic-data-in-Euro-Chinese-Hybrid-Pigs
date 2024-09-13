#!/bin/bash
#SBATCH -J ~10min_Musta
#SBATCH -N 1 -n 6
#SBATCH -e /home/gemeichenyu/log/phase-prejob-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/phase-prejob-%j_%a.log
#SBATCH -p all
#SBATCH --mem=30Gb
#SBATCH -a 1-18

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

#juicer=/home/gemeichenyu/soft/juicer-1.6/CPU/juicer-phase-pre.sh

#############setting input and output directory##########
sample= #list of offspring(20101,20203,5572,5814,M15S1)
OUTPUT=/home/gemeichenyu/call_loop/HiC/${sample}
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
##################YOUR RUNNING SCRIPTS############################
##################################################################
cd ${tmpdir}/${Work_dir}
echo "Now We are working on ${tmpdir}/${Work_dir}!"
chr=`cat /home/gemeichenyu/call_loop/HiC/chr.txt|head -$PBS_ARRAYID | tail -1`  ## The list of  autosome (chr1-chr18)

singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir} /home/guilu/software/hicexplorer_3_7_2.sif hicConvertFormat -m $OUTPUT/${chr}_inter_30_test.hic --inputFormat hic --outputFormat cool -o ${chr}.cool --resolutions 5000
singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir} /home/guilu/software/hicexplorer_3_7_2.sif hicConvertFormat -m ${chr}_5000.cool  --inputFormat cool --outputFormat cool -o ${chr}_5000_norm.cool --resolutions 5000 --correction_name KR
singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir} ~/soft/02_HiCtools.sif mustache --file ${chr}_5000_norm.cool  --outfile ${chr}_5000_mustache.loop  --resolution 5000 --processes 6 --pThreshold 0.05 --normalization weight  --chromosomeSize ~/HiC/restriction_sites/DRC.MotherHap.fa.size

#########CP BACK AND SAVE YOUR RESULTS #####################
cp *norm*cool   ${OUTPUT}
cp *mustache.loop  ${OUTPUT}

######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
