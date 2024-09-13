#/bin/bash
#SBATCH -J ~10min_Musta
#SBATCH -N 1 -n 6
#SBATCH -e /home/gemeichenyu/log/phase-prejob-%j_%a.err
#SBATCH -o /home/gemeichenyu/log/phase-prejob-%j_%a.log
#SBATCH -p all
#SBATCH --mem=20gb
#SBATCH -a 1

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
OUTPUT=/home/gemeichenyu/compartment_TAD/map_construct/${sample}/norm_cool
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
inputfile=`cat /home/gemeichenyu/compartment_TAD/map_construct/${sample}/name.txt|head -$PBS_ARRAYID | tail -1`
name=`echo $inputfile| awk -F "/" '{print $NF}'|awk -F "." '{print $1}'` 
chr=`echo $name|awk -F "_" '{print $1}'|sed 's/chr//g'`
singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir} /home/guilu/software/hicexplorer_3_7_2.sif hicConvertFormat -m ${name}.hic --inputFormat hic --outputFormat cool -o ${name}.cool --resolutions 20000

singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir} /home/guilu/software/hicexplorer_3_7_2.sif hicConvertFormat -m $inputfile  --inputFormat cool --outputFormat cool -o ${name}_norm.cool --resolutions 20000 --correction_name KR

singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir} /home/guilu/software/hicexplorer_3_7_2.sif hicConvertFormat -m ${name}_norm.cool  --inputFormat cool --outputFormat h5 -o ${name}_norm.h5 --resolutions 20000 --chromosome $chr

singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir} /home/guilu/software/hicexplorer_3_7_2.sif hicFindTADs -m ${name}_norm.h5  --outPrefix ${name} --correctForMultipleTesting fdr --chromosome $chr --numberOfProcessors 40
#########CP BACK AND SAVE YOUR RESULTS #####################
cp  *  ${OUTPUT}


######REMOVE tmp directory #################################
echo "Remove tmp files at ${Work_dir}"
rm -rf ${tmpdir}/${Work_dir}
#conda deactivate

echo "Job finished at:" `date`
