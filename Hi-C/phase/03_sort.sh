#!/bin/bash
#SBATCH -J diploid_sort
#SBATCH -N 1 -n 80
#SBATCH -e /home/gemeichenyu/log/diploid_sort_job-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/diploid_sort_job-%j_%a.log
#SBATCH -p all
#SBATCH --mem=100Gb
#SBATCH -a 2

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
parent= pat
#INPUT=/home/guilu/

#############working directory setting###########
uid="lcy" #user id
ls_date=`date +m%d%H%M%S` #Set Random date and time
Work_dir=${uid}_${ls_date}_${PBS_ARRAYID}  #
OUTPUT=/home/tmpdir/Lichenyu/${sample}
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
if [ $parent == pat ]
then
cat ${OUTPUT}/L1/aligned/pat.txt ${OUTPUT}/L2/aligned/pat.txt ${OUTPUT}/L3/aligned/pat.txt ${OUTPUT}/L4/aligned/pat.txt ${OUTPUT}/L5/aligned/pat.txt ${OUTPUT}/L6/aligned/pat.txt ${OUTPUT}/L7/aligned/pat.txt  ${OUTPUT}/L8/aligned/pat.txt ${OUTPUT}/L9/aligned/pat.txt ${OUTPUT}/L10/aligned/pat.txt ${OUTPUT}/L11/aligned/pat.txt ${OUTPUT}/L12/aligned/pat.txt ${OUTPUT}/L13/aligned/pat.txt | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8" "$9}' > pre_sort_pat.txt 
sort --parallel=80 -k2,2d -k6,6d -k4,4n -k8,8n -k1,1n -k5,5n -k3,3n pre_sort_pat.txt  > pat.txt  
#~/soft/juicer-1.6/CPU/common/juicer_tools pre pat.txt  -r 100000,20000,10000,5000 paternal.hic  ~/HiC/restriction_sites/DRC.MotherHap.fa.size
else
cat ${OUTPUT}/L1/aligned/mat.txt ${OUTPUT}/L2/aligned/mat.txt ${OUTPUT}/L3/aligned/mat.txt ${OUTPUT}/L4/aligned/mat.txt ${OUTPUT}/L5/aligned/mat.txt ${OUTPUT}/L6/aligned/mat.txt ${OUTPUT}/L7/aligned/mat.txt  ${OUTPUT}/L8/aligned/mat.txt ${OUTPUT}/L9/aligned/mat.txt ${OUTPUT}/L10/aligned/mat.txt ${OUTPUT}/L11/aligned/mat.txt ${OUTPUT}/L12/aligned/mat.txt ${OUTPUT}/L13/aligned/mat.txt | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8" "$9}' > pre_sort_mat.txt
sort --parallel=80 -k2,2d -k6,6d -k4,4n -k8,8n -k1,1n -k5,5n -k3,3n pre_sort_mat.txt  > mat.txt                            
#~/soft/juicer-1.6/CPU/common/juicer_tools pre mat.txt  -r 100000,20000,10000,5000 maternal.hic  ~/HiC/restriction_sites/DRC.MotherHap.fa.size
fi
#######CP BACK AND SAVE YOUR RESULTS #####################
cp *at.txt ${OUTPUT}
######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
