#!/bin/bash

# Shell commands
samples=("20101" "20203" "5572" "5814" "M15S1")
chromosomes=$(seq 1 18)

for sample in "${samples[@]}"; do
  for chr in ${chromosomes}; do
    echo "Processing sample ${sample}, chromosome ${chr}..."

    # Running the $straw command for paternal and maternal Hi-C files
    $straw NONE output/${sample}/${chr}_paternal.hic ${chr} ${chr} BP 20000 > ${sample}_chr${chr}_20kb_paternal.txt
    $straw NONE output/${sample}/${chr}_maternal.hic ${chr} ${chr} BP 20000 > ${sample}_chr${chr}_20kb_maternal.txt

    # Call the R script using Rscript
    Rscript tad_compare.r ${sample} ${chr}

  done
done


