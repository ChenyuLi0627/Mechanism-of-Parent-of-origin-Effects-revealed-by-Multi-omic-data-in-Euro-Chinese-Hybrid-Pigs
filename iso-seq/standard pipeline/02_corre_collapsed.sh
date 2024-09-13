#!/bin/bash
#PBS -N corre_collapsed
#PBS -l nodes=1:ppn=15,mem=20gb
#PBS -e /home/rnaqc/ProMe/workshop/PacBio_workshop/slurm.log
#PBS -o /home/rnaqc/ProMe/workshop/PacBio_workshop/slurm.log
#PBS -q fat
#PBS -t 1
# Kill script if any commands fail
set -e
source /opt/software/anaconda2/bin/activate
echo "Job Start at `date`"

#Set input & final output path
output=/home/rnaqc/ProMe/workshop/PacBio_workshop
genome=/home/rnaqc/ref/gmap_DRC/DRC.MotherHap
tmpdir=/tmpdisk  #892Gb
collapse=/home/rnaqc/soft
fa2fq=/opt/software/cDNA_Cupcake/sequence
ref= #reference genome
nprocs=`wc -l < $PBS_NODEFILE`
#Setup tempdisk for output
uid="Chenyuli" #user id
ls_date=`date +m%d%H%M%S` #Set Random date and time
Work_dir=${uid}_${ls_date}_${PBS_ARRAYID}  #temp directory
cd ${tmpdir}
echo "the temprory directory is $tmpdir"
mkdir ${Work_dir}

###############################################################################
##################                                                   ##########
##################     This is programming part                      ##########
##################                                                   ##########
###############################################################################
cd ${tmpdir}/${Work_dir}
inputfile=`cat ${output}/polished.txt|head -${PBS_ARRAYID}|tail -1`
echo "$inputfile" |sed 's/.polished.hq.fasta//' |awk -F/ '{print $NF}'
outputfile=`echo "$inputfile" | sed 's/.polished.hq.fasta//' |awk -F/ '{print $NF}'`

gmap -t 15 -D ${genome} -d $ref  -f samse -n 1 ${inputfile}  > ${outputfile}.corrected_fa.sam

sort -k 3,3 -k 4,4n ${outputfile}.corrected_fa.sam > ${outputfile}.corrected_fa.sorted.sam

python ${collapse}/collapse_isoforms_by_sam.py --input ${inputfile}  -s ${outputfile}.corrected_fa.sorted.sam --dun-merge-5-shorter -o ${outputfile}


cp -r ${tmpdir}/${Work_dir}/* ${output}

###############################################################################
##################                                                   ##########
##################     This is end of programming                    ##########
#################                                                   ##########
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




