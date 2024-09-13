setwd("E:\\Rwork\\CRE\\LD_diff_peaks")
#setwd("E:\\Rwork\\CRE\\BF_diff_peaks")
samples <- c("20101", "20203", "5572", "5814", "M15S1")
assays <- c("H3K27me3","H3K27ac", "H3K4me3",  "CTCF","H3K4me1")

# Function to process a single file
process_file <- function(sample, assay) {
  file_name <- paste0(sample, "_BF_", assay, "_DiffPeaks_filter.txt")
  if (file.exists(file_name)) {
    data <- read.table(file_name, header = FALSE)
    data$peak <- paste(data$V1, data$V2, data$V3, sep = "_")
    data <- data[, c("V9", "peak")]
    colnames(data) <- c(paste(sample, assay, sep = "_"), "peak")
    return(data)
  } else {
    warning(paste("File not found:", file_name))
    return(NULL)
  }
}

# Function to summarize data
summarize_data <- function(data) {
  # Replace NA with 0 and non-NA with 1
  data[, 2:ncol(data)] <- lapply(data[, 2:ncol(data)], function(x) ifelse(is.na(x), 0, 1))
  data$nonzero_count <- rowSums(data[, 2:ncol(data)] != 0)
  summary <- as.data.frame(table(data$nonzero_count))
  colnames(summary) <- c("nonzero_count", "count")
  return(summary)
}

# Initialize list to store results
result_list <- list()

# Loop through each assay
for (assay in assays) {
  data_list <- list()
  
  # Loop through each sample
  for (sample in samples) {
    cat("Processing file for sample:", sample, "and assay:", assay, "\n")
    data <- process_file(sample, assay)
    if (!is.null(data)) {
      data_list[[sample]] <- data
    }
  }
  
  # Check if we have any data to merge
  if (length(data_list) > 0) {
    # Merge all sample data for the current assay
    cat("Merging data for assay:", assay, "\n")
    merged_data <- Reduce(function(x, y) merge(x, y, by = "peak", all = TRUE), data_list)
    
    # Summarize the merged data
    cat("Summarizing data for assay:", assay, "\n")
    summary <- summarize_data(merged_data)
    summary$assay <- assay
    
    # Store the result
    result_list[[assay]] <- summary
  } else {
    warning(paste("No data found for assay:", assay))
  }
}

# Combine all results into one data frame
if (length(result_list) > 0) {
  final_result <- do.call(rbind, result_list)
  print(final_result)
} else {
  cat("No results to display.\n")
}




##plot
library(ggbreak)
library(ggplot2)
final_result$assay <- factor(final_result$assay, levels = c("H3K4me3", "H3K27ac", "H3K4me1", "H3K27me3", "CTCF"))
ggplot(final_result, aes(x = factor(nonzero_count), y = count, fill = assay)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_minimal() +
  labs(x = "Frequency of PHSMs and PS CTCF of LD", y = "PS CTCF") +
  theme(axis.title = element_text(size = 14),
        axis.text = element_text(size = 12),
        legend.title = element_text(size = 12),
        legend.text = element_text(size = 10)) +
  scale_fill_manual(values = c("H3K4me3" = "cyan4", "H3K27ac" = "orange", 
                               "H3K4me1" = "purple", "H3K27me3" = "tan", "CTCF" = "salmon")) +
  scale_y_break(c(3500, 10000), scales = 0.5)