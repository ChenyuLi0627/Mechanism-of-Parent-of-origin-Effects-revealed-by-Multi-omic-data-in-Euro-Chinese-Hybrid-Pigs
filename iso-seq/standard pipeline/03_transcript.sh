#!/bin/bash
#PBS -N transcript
#PBS -l nodes=1:ppn=20,mem=20gb
#PBS -e /home/rnaqc/ProMe/workshop/PacBio_workshop/slurm.log
#PBS -o /home/rnaqc/ProMe/workshop/PacBio_workshop/slurm.log
#PBS -q cu
#PBS -t 1
# Kill script if any commands fail
set -e
source /opt/software/anaconda2/bin/activate
echo "Job Start at `date`"

#Set input & final output path
output=/home/rnaqc/ProMe/workshop/PacBio_workshop
fa2fq=/opt/software/cDNA_Cupcake/sequence
python27=/opt/software/anaconda2/bin/python2.7 
sqanti_qc=/home/rnaqc/soft/sqanti
get_abundance_post_collapse=/opt/software/cDNA_Cupcake/cupcake/tofu
annotation=/opt/software/cDNA_Cupcake/annotation
ref= #reference genome
gtf= #gtf of reference genome
index= #index of gmap
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
inputfile=`cat ${output}/collapsed_rep_fa.txt|head -${PBS_ARRAYID}|tail -1`
echo "$inputfile" |sed 's/.collapsed.rep.fa//' |awk -F/ '{print $NF}'
outputfile=`echo "$inputfile" | sed 's/.collapsed.rep.fa//' |awk -F/ '{print $NF}'`
cp   ${output}/${outputfile}*cluster_report.csv   ${tmpdir}/${Work_dir} &&
cp   ${output}/${outputfile}.ignored_ids.txt        ${tmpdir}/${Work_dir} &&
cp   ${output}/${outputfile}.corrected*             ${tmpdir}/${Work_dir} &&
cp   ${output}/${outputfile}.collapsed*             ${tmpdir}/${Work_dir} &&  #Put all the result files from step 2 into tmpdisk (beforehand, put the first step polished/clustered.cluster_report.csv into the results of step 2)
python ${fa2fq}/fa2fq.py  ${outputfile}.collapsed.rep.fa &&
mv ${outputfile}.collapsed.rep.fastq ${outputfile}.collapsed.rep.fq &&
${python27} ${sqanti_qc}/sqanti_qc.py  ${outputfile}.collapsed.rep.fa $gtf  $ref -n -x $index &&
python ${get_abundance_post_collapse}/get_abundance_post_collapse.py ${outputfile}.collapsed  ${outputfile}.polished.cluster_report.csv 
python ${annotation}/make_file_for_subsampling_from_collapsed.py -i ${outputfile}.collapsed -o ${outputfile}.for_subsampling -m2 ${outputfile}.collapsed.rep_classification.txt 
python ${annotation}/subsample.py --by refgene --min_fl_count 2 --step 1000 ${outputfile}.for_subsampling.all.txt > ${outputfile}.rarefaction.by_refgene.min_fl_2.txt 
python ${annotation}/subsample.py --by refisoform --min_fl_count 2 --step 1000 ${outputfile}.for_subsampling.all.txt > ${outputfile}.rarefaction.by_refisoform.min_fl_2.txt 
echo "done"
cp -r ${tmpdir}/${Work_dir}/* ${output}

###############################################################################
##################                                                   ##########
##################     This is end of programming                    ##########
##################                                                   ##########
###############################################################################

#Attention, you must delete the temp directory before finished the Job!!!!
echo "Remove tmp files at ${Work_dir}"
cd ${output}
zm -rf ${tmpdir}/${Work_dir}


conda deactivate
#get time end the job
echo "Job finished at:" `date`
