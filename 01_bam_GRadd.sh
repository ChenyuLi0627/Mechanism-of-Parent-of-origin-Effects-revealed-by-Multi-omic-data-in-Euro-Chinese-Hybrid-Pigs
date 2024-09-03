#!/bin/bash
#PBS -N GRadd
#PBS -l nodes=1:ppn=20,mem=20gb
#PBS -e /home/Lichenyu/qsub_log 
#PBS -o /home/Lichenyu/qsub_log
#PBS -q cu
#PBS -t 11-20
# Kill script if any commands fail
set -e
echo "Job Start at `date`"

#Set input & final output path
#pacbio=/home/goldenpigs/0.data/1.pacbio/BMX
input=/work/LCY_tmp/RNAseq/unphased
output=/work/LCY_tmp/RNAseq/unphased
#primer=/work/goldenpigs/1.HuangYZ/12.BMX
tmpdir=/tmpdisk  #892Gb

#Get Number of running process
nprocs=`wc -l < $PBS_NODEFILE`
#Setup tempdisk for output
uid="Chenyuli" #user id
ls_date=`date +m%d%H%M%S` #Set Random date and time
Work_dir=${uid}_${ls_date}_${PBS_ARRAYID}  #temp directory
echo "the temprory directory is $tmpdir"
mkdir ${tmpdir}/${Work_dir}
cd ${tmpdir}/${Work_dir}

###############################################################################
##################                                                   ##########
##################     This is programming part                      ##########
##################                                                   ##########
###############################################################################
inputfile=`cat ${input}/sample.txt|head -${PBS_ARRAYID}|tail -1`
echo "$inputfile" |sed 's/.sorted.bam//' |awk -F/ '{print $NF}'
outputfile=`echo "$inputfile" | sed 's/.sorted.bam//' |awk -F/ '{print $NF}'`
RG=`echo $outputfile |awk -F "_" '{print $2}'`
singularity exec -B /work/LCY_tmp/RNAseq/unphased:/work/LCY_tmp/RNAseq/unphased   /home/Singusoft/picard.sif java -jar /usr/local/bin/picard/picard.jar  AddOrReplaceReadGroups I=$inputfile  O=/work/LCY_tmp/RNAseq/unphased/${outputfile}_sorted_add.bam RGID=${RG} RGLB=library1  RGPL=illumina  RGPU=unit1 RGSM=${RG}
#cp -r ${tmpdir}/${Work_dir}/* ${output}

###############################################################################
##################                                                   ##########
##################     This is end of programming                    ##########
##################                                                   ##########
###############################################################################


#Copy my teminal files to output
# cp *.vcf ${OUTPUT}/.

#Attention, you must delete the temp directory before finished the Job!!!!
echo "Remove tmp files at ${Work_dir}"
cd ${output}
rm -rf ${tmpdir}/${Work_dir}


conda deactivate
#get time end the job
echo "Job finished at:" `date`
