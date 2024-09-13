#!/bin/bash
#PBS -N ccs
#PBS -l nodes=fat01:ppn=20,mem=20gb
#PBS -e /home/rnaqc/ProMe/workshop/PacBio_workshop/slurm.log
#PBS -o /home/rnaqc/ProMe/workshop/PacBio_workshop/slurm.log
#PBS -q fat
#PBS -t 1
# Kill script if any commands fail
set -e
source /opt/software/anaconda2/bin/activate
echo "Job Start at `date`"

#Set input & final output path
#pacbio=/home/goldenpigs/0.data/1.pacbio/BMX
output=/home/rnaqc/ProMe/workshop/PacBio_workshop
primer=/home/rnaqc/ProMe/output/primer.fa
#input=/home/goldenpigs/1.Huangyizhong/15.pacbio-analysis/4.primer
isoseq3=/home/goldenpigs/1.Huangyizhong/softwares/miniconda3/bin
#primer=/work/goldenpigs/1.HuangYZ/12.BMX
tmpdir=/tmpdisk  #892Gb

#Get Number of running process
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
inputfile=`cat ${output}/PBlist.txt|head -${PBS_ARRAYID}|tail -1`
echo "$inputfile" |sed 's/.bam//' |awk -F/ '{print $NF}'
outputfile=`echo "$inputfile" | sed 's/.bam//' |awk -F/ '{print $NF}'`

#dataset create --type TranscriptSet merged.flnc.xml movie1.flnc.bam movie2.flnc.bam movieN.flnc.bam
#dataset create --type SubreadSet merged.subreadset.xml movie1.subreadset.xml movie2.subreadset.xml movieN.subreadset.xml

${isoseq3}/ccs ${inputfile} ${outputfile}.ccs.bam --min-rq 0.99

${isoseq3}/lima ${outputfile}.ccs.bam  ${primer}  ${outputfile}.fl.bam --isoseq --peek-guess

${isoseq3}/isoseq3 refine ${outputfile}.fl.primer_5p--primer_3p.bam ${primer}  ${outputfile}.flnc.bam --require-polya

${isoseq3}/isoseq3 cluster ${outputfile}.flnc.bam ${outputfile}_clustered.bam --verbose --use-qvs

${isoseq3}/isoseq3 polish ${outputfile}_clustered.bam  ${inputfile}  ${outputfile}.polished.bam 

cp -r ${tmpdir}/${Work_dir}/* ${output}

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
