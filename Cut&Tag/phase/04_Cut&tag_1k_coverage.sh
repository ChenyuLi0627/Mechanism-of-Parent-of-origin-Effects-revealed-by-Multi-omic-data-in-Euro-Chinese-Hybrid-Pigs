#/bin/bash
#PBS -N cuttag
#PBS -l nodes=cu18:ppn=1,mem=40gb
#PBS -e /home/Lichenyu/qsub_log
#PBS -o /home/Lichenyu/qsub_log
#PBS -q cu
#PBS -t 2

# Kill script if any commands fail
set -e
echo "Job starts at:"
date

OUTPUT=/home/Lichenyu/bin_coverage/tmp
echo "job start at:"
date
# set working directory


uid="rnaqc" #user id
ls_date=`date +m%d%H%M%S` 
cd /tmpdisk  
Work_dir=${uid}_${ls_date}_${PBS_ARRAYID} 
mkdir ${Work_dir} 
cd $Work_dir 
######################Scripts###################
inputfile=`cat /home/Lichenyu/cuttag_bam/name.txt |head -${PBS_ARRAYID}|tail -1`
name=`echo $inputfile|awk -F"/" '{print $NF}' |sed s/_bowtie2.mapped.bam//g` 
~/soft/bedtools coverage -sorted  -a ~/ref/DRC.MotherHap.1k.bed  -b /home/Lichenyu/cuttag_bam/${name}_bowtie2.mapped.bam  |awk '{print $1"\t"$2"\t"$3"\t"$4}' >  ${name}.bincoverage

cp * ${OUTPUT}

cd /tmpdisk
rm -rf ${Work_dir} 
echo "The program normally finished at"
date
