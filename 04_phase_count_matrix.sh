#!/bin/bash

# Check if the tissue argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tissue>"
    exit 1
fi

# Assign the command-line argument to the tissue variable
tissue=$1

# Sample values to iterate over
samples=("20101" "20203" "5572" "5814" "M15S1")

# Loop through each sample value
for i in "${samples[@]}"; do
    echo "Processing sample: $i with tissue: $tissue"

    # Generate the list of files
    awk -v tissue="$tissue" -v sample="$i" \
        'BEGIN {print tissue"_"sample"_H1\t"tissue"_"sample".RNA_H1_transcript.gtf"}' \
        > "${tissue}_${i}_list.txt"

    awk -v tissue="$tissue" -v sample="$i" \
        'BEGIN {print tissue"_"sample"_H2\t"tissue"_"sample".RNA_H2_transcript.gtf"}' \
        >> "${tissue}_${i}_list.txt"

    # Debugging: Verify the contents of the file
    echo "Contents of ${tissue}_${i}_list.txt:"
    cat "${tissue}_${i}_list.txt"

    # Run the Python script with Singularity
    singularity exec ~/soft/HiCcompare_MatrixeQTL python ~/soft/stringtie-master/prepDE.py3 \
        -i "${tissue}_${i}_list.txt" \
        -g "${tissue}_${i}_matrix.csv"

    sed -i 's/gene://g;s/,/\t/g' ${tissue}_${i}_matrix.csv
done

