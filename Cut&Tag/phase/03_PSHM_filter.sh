# Define tissues, samples, and marks
tissues=("BF" "LD")
samples=("20101" "20203" "5572" "5814" "M15S1")
marks=("H3K4me3" "H3K27ac" "H3K27me3" "H3K4me1" "CTCF")

# Loop through samples, tissues, and marks
for sample in "${samples[@]}"; do
  for tissue in "${tissues[@]}"; do
    for mark in "${marks[@]}"; do
      # Perform operations similar to the previous code
      # Assuming there's a DiffPeaks file for each sample-tissue-mark combination
      input_diff_file="${sample}_${tissue}_${mark}_diff_DiffPeaks.txt"
      input_peak_file="/home/gemeichenyu/transfer/cuttag/Peak/${sample}_${tissue}_H3K4me1.H1_peaks.narrowPeak"
      output_file="${sample}_${tissue}_${mark}_DiffPeaks_filter.txt"
      
      # Check if the input file exists
      if [[ -f "$input_diff_file" ]]; then
        sed -i '1d;s/_/\t/g' "$input_diff_file"
        
        # Sort, merge, and intersect
        if [[ -f "$input_peak_file" ]]; then
          cat "$input_peak_file" | \
          sort -k1,1V -k2,2n -k3,3n | \
          ~/soft/bedtools merge | \
          ~/soft/bedtools intersect -a - -b "$input_diff_file" -wa -wb | \
          awk '{print $4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11"\t"$12}' > "$output_file"
        else
          echo "Input peak file not found: $input_peak_file"
        fi
      else
        echo "Input DiffPeaks file not found: $input_diff_file"
      fi
    done
  done
done