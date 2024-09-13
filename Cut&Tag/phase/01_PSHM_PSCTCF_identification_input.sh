# Define tissues, histone modifications, TF and samples
tissues=("BF" "LD")
histones=("H3K27ac" "H3K4me3" "H3K4me1" "H3K27me3")
samples=("20101" "20203" "5572" "5814" "M15S1")

# Loop through each tissue
for tissue in "${tissues[@]}"
do
  # Loop through each histone modification
  for histone in "${histones[@]}"
  do
    # Create consensus peaks for the current tissue and histone modification
    cat *_${tissue}_${histone}_peaks.narrowPeak | sort -k1,1V -k2,2n -k3,3n | ~/soft/bedtools merge > ${tissue}_${histone}_consensus.narrowPeak

    # Loop through each sample for the current tissue and histone modification
    for sample in "${samples[@]}"
    do
      # Calculate coverage for replicates H1 and H2
      ~/soft/bedtools coverage -a ${tissue}_${histone}_consensus.narrowPeak -b ${sample}_${tissue}_${histone}_bowtie2_cuttag_H1.bam | cut -f 1,2,3,4 > ${sample}_${tissue}_${histone}_bowtie2_cuttag_H1.bedgraph &&
      ~/soft/bedtools coverage -a ${tissue}_${histone}_consensus.narrowPeak -b ${sample}_${tissue}_${histone}_bowtie2_cuttag_H2.bam | cut -f 1,2,3,4 > ${sample}_${tissue}_${histone}_bowtie2_cuttag_H2.bedgraph &&
      
      # Combine the coverage data from H1 and H2 into a single input file
      paste ${sample}_${tissue}_${histone}_bowtie2_cuttag_H1.bedgraph ${sample}_${tissue}_${histone}_bowtie2_cuttag_H2.bedgraph | awk '{print $1"_"$2"_"$3"\t"$4"\t"$8}' > ${sample}_${tissue}_${histone}_bowtie2_cuttag_H1H2.input
    done
  done
done
