

# Load necessary libraries
library(TADCompare)
# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
sample <- args[1]
chr <- args[2]

# Read in data
paternal <- read.table(paste0(sample, "_chr", chr, "_20kb_paternal.txt"), header = FALSE)
maternal <- read.table(paste0(sample, "_chr", chr, "_20kb_maternal.txt"), header = FALSE)

# Run TADCompare
# Call TADs using SpectralTAD
bed_coords1 <- bind_rows(SpectralTAD(paternal, chr = chr, levels = 3))
bed_coords2 <- bind_rows(SpectralTAD(maternal, chr = chr, levels = 3))

# Placing the data in a list for the plotting procedure
Combined_Bed <- list(bed_coords1, bed_coords2)

# Running TADCompare with pre-specified TADs
TD_Compare <- TADCompare(paternal, maternal, resolution = 20000, pre_tads = Combined_Bed)

# Write the output to a file
write.table(TD_Compare$TAD_Frame, paste0(sample, "_chr", chr, "_20kb_diffTADboundaries.txt"), quote = FALSE, row.names = FALSE)