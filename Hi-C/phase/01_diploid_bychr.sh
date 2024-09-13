#!/bin/bash
#SBATCH -J ~1hphase_diploid
#SBATCH -N 1 -n 10
#SBATCH -e /home/gemeichenyu/log/phase_diploid_job-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/phase_diploid_job-%j_%a.log
#SBATCH -p all
#SBATCH --mem=30Gb
#SBATCH -a 1-19

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
juiceDir=/home/gemeichenyu/HiC
#############setting input and output directory##########
sample= #list of offspring(20101,20203,5572,5814,M15S1)
##运行修改处
batch=L13
OUTPUT=/home/tmpdir/Lichenyu/${sample}/${batch}/aligned
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
awk -f /home/gemeichenyu/soft/juicer-1.6/UGER/scripts/vcftotxt.awk ${sample}_chr.pretag.phased.vcf  ##*pretag.phased.vcf was available in phasing pipeline 
awk  -v chr=$chr '($2==chr && $2==$6 &&  $9 >= 30 && $12 >= 30)' ${OUTPUT}/merged_nodups.txt > ${sample}_${batch}_merged_nodups_${chr}.txt
${juiceDir}/scripts/common/diploid.pl -s ${sample}_chr_pos.txt  -o ${sample}_paternal_maternal.txt ${sample}_${batch}_merged_nodups_${chr}.txt > ${sample}_${batch}_diploid_${chr}.txt
wc -l ${sample}_${batch}_merged_nodups_${chr}.txt ${sample}_${batch}_diploid_${chr}.txt
#######CP BACK AND SAVE YOUR RESULTS #####################
cp ${sample}_${batch}_diploid_${chr}.txt  ${OUTPUT}

######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
