#!/bin/bash
#SBATCH -J ~1D_juicer
#SBATCH -N 1 -n 10
#SBATCH -e /home/gemeichenyu/log/phase-prejob-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/phase-prejob-%j_%a.log
#SBATCH -p all
#SBATCH --mem=20Gb
#SBATCH -a 2-6

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
outputfile=`echo "$inputfile" | sed 's/_bowtie2.mapped.bam//' |awk -F/ '{print $NF}'`
RG=`echo $outputfile |awk -F "_" '{print $1}'`
~/soft/samtools1.9/bin/samtools sort -@20 -o /home/gemeichenyu/transfer/cuttag/bin_coverage/${outputfile}_bowtie2.sorted.bam /home/gemeichenyu/transfer/cuttag/bin_coverage/${outputfile}_bowtie2.mapped.bam
~/soft/samtools1.9/bin/samtools index -@20 /home/gemeichenyu/transfer/cuttag/bin_coverage/${outputfile}_bowtie2.sorted.bam 
singularity exec  ~/../guilu/software/picard.sif java -jar /usr/local/bin/picard/picard.jar  AddOrReplaceReadGroups I=/home/gemeichenyu/transfer/cuttag/bin_coverage/${outputfile}_bowtie2.sorted.bam  O=/home/gemeichenyu/transfer/cuttag/bin_coverage/${outputfile}_sorted_add.bam RGID=${RG} RGLB=library1  RGPL=illumina  RGPU=unit1 RGSM=${RG}

#########CP BACK AND SAVE YOUR RESULTS #####################
cp * ${output}

######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
