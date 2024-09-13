#!/bin/bash

# Create an empty file to store the result
output_file="merged_output.txt"
> $output_file

# Create header
header=""
for file in *.bincoverage; do
    prefix=$(basename "$file" .bincoverage)
    header="${header}${prefix}\t"
done
header=${header%$'\t'}  # Remove trailing tab
echo -e "$header" >> $output_file

# Extract the fourth column from each file and save to a temporary file
temp_files=()
for file in *.bincoverage; do
    temp_file=$(mktemp)
    cut -f4 "$file" > "$temp_file"
    temp_files+=("$temp_file")
done

# Paste all the extracted columns together
paste "${temp_files[@]}" >> $output_file

# Clean up temporary files
rm "${temp_files[@]}"
