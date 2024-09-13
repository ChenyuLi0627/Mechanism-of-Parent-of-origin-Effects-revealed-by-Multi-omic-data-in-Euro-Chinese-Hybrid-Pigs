#/bin/bash
#PBS -N Hisat_mapping
#PBS -l nodes=1:ppn=1,mem=10gb
#PBS -e /home/Lichenyu/qsub_log
#PBS -o /home/Lichenyu/qsub_log
#PBS -q cu
#PBS -t  1-5

set -e
echo "Job Start at `date`"

INPUT=/home/Lichenyu/expand_five_RNAseq
output=/home/Lichenyu/expand_five_RNAseq
RseqPath=/opt/software/anaconda2/bin
BED=/home/Lichenyu/ref/DRCv19_mother_DRCv20_liftoff.sorted.bed
tmpdir=/tmpdisk  #892Gb
ref= #hisat2 index of reference genome
#Get Number of running process
nprocs=`wc -l < $PBS_NODEFILE`
#Setup tempdisk for output
uid="Chenyuli" #user id
ls_date=`date +m%d%H%M%S` #Set Random date and time
Work_dir=${uid}_${ls_date}_${PBS_ARRAYID}  #temp directory
echo "the temprory directory is $tmpdir"
mkdir ${tmpdir}/${Work_dir}
cd ${tmpdir}/${Work_dir}
inputfile=`cat ${output}/sample.txt|head -${PBS_ARRAYID}|tail -1` ##(list of all samples)
name=`echo $inputfile  |awk -F "/" '{print $NF}'|sed 's/_[0-9].clean.fq.gz//g'`
echo $name start.............
#singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir} /home/Singusoft/fastp.sif -l 100 -i ${name}*_raw_1.fq.gz -o ${name}_1.clean.fq.gz -I ${name}*_raw_2.fq.gz -O ${name}_2.clean.fq.gz
singularity exec -B ${tmpdir}/${Work_dir}:${tmpdir}/${Work_dir}  /home/Singusoft/hisat2.sif  hisat2 -p $nprocs -x  $ref -I 0 --qc-filter -X 500  -1 ${INPUT}/${name}_1.clean.fq.gz -2 ${INPUT}/${name}_2.clean.fq.gz  -S ${name}.sam
~/soft/samtools view -@ 10 -Sbh ${name}.sam > ${name}.bam
~/soft/samtools sort -@ 10 -o ${name}.sorted.bam ${name}.bam
~/soft/samtools index -@ 10 ${name}.sorted.bam
$RseqPath/bam_stat.py -i ${name}.bam  > ${name}_bam_stat.log
$RseqPath/infer_experiment.py -r $BED -i ${name}.bam  >${name}_inf_exp.log

echo "done"
cp -r ${tmpdir}/${Work_dir}/*sorted*  ${output}
cp -r ${tmpdir}/${Work_dir}/*log  ${output}

###############################################################################
##################                                                   ##########
##################     This is end of programming                    ##########
##################                                                   ##########
###############################################################################

#Attention, you must delete the temp directory before finished the Job!!!!
echo "Remove tmp files at ${Work_dir}"
cd ${output}
rm -rf ${tmpdir}/${Work_dir}


conda deactivate
#get time end the job
echo "Job finished at:" `date`

