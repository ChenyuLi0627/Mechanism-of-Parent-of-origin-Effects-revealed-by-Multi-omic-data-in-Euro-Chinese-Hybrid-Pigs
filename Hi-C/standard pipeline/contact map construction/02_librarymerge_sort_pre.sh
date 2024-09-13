#!/bin/bash
#SBATCH -J librarymerge_sort_pre
#SBATCH -N 1 -c 80
#SBATCH -e /home/gemeichenyu/vv_hic/log/DIPpre-%j_%a.err
#SBATCH -o /home/gemeichenyu/vv_hic/log/DIPpre-%j_%a.log
#SBATCH -p  cu36
#SBATCH --mem=100Gb
#SBATCH -a 1

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

echo "Number of threads is $nprocs"

##########software path setting#############


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

#####copy data to node computers ###################

##################################################################
########## YOUR RUNNING SCRIPTS                      #############
##################################################################
cd ${tmpdir}/${Work_dir}
echo "Now We are working on ${tmpdir}/${Work_dir}!"
cd ${tmpdir}/${Work_dir}
echo "Now We are working on ${tmpdir}/${Work_dir}!"
inputfile=`cat /home/gemeichenyu/HiC/sample.txt|head -$PBS_ARRAYID | tail -1`  ##The name list of samples
 dir=/home/gemeichenyu/scripts

###calculate_resolution
cat ${dir}/${inputfile}/${inputfile}_*/aligned/merged30.txt > merged30_total.txt &&
${dir}/calculate_map_resolution_merge30.sh merged30_total.txt temp.txt resolution_res.txt &&
rm temp.txt


###sort
sort --parallel=80 -k2,2d -k6,6d -k4,4n -k8,8n -k1,1n -k5,5n -k3,3n merged30_total.txt > merged30_total_sort.txt &&

rm merged30_total.txt

###pigz
/home/gemeichenyu/soft/pigz -p 40 merged30_total_sort.txt &&
cp merged30_total_sort.txt.gz ${dir}/${inputfile} &&

###juicer_tool pre
~/soft/juicer/CPU/common/juicer_tools pre  merged30_total_sort.txt.gz -r 100000,20000,10000,5000 ${inputfile}_inter_30.hic ~/HiC/restriction_sites/DRC.MotherHap.fa.size &&


cp ./* ${dir}/${inputfile}/ &&





#wcat /home/gemeichenyu/AllFlash/Chenyuli/Dip2.0_pilot/${inputfile}/${inputfile}*/aligned/merged30.txt|sort -S 50% --parallel=15 -T /home/gemeichenyu/AllFlash/Chenyuli/Dip2.0_pilot/Intestines8/temp -k2,2d -k6,6d|~/soft/pigz -p 30 > /home/gemeichenyu/AllFlash/Chenyuli/Dip2.0_pilot/${inputfile}/merged_nodups.txt.gz
#~/soft/juicer/CPU/common/juicer_tools pre  /home/gemeichenyu/AllFlash/Chenyuli/Dip2.0_pilot/${inputfile}/merged_nodups.txt.gz -r 100000,20000,10000,5000   /home/gemeichenyu/AllFlash/Chenyuli/Dip2.0_pilot/${inputfile}/${inputfile}_inter_30.hic ~/HiC/restriction_sites/DRC.MotherHap.fa.size


#########CP BACK AND SAVE YOUR RESULTS #####################
#cp * ${OUTPUT}/.

######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
