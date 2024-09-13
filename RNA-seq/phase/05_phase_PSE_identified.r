# Load necessary library
library(ggplot2)

# Define tissue types and samples
tissue <- c("BF","LD")
samples <- c("20101", "20203", "5572", "5814", "M15S1", "M15S2")

# Loop through each tissue type
for (t in tissue) {
  for (sample in samples) {
    # Read the input data file, skip the first line and specify tab as separator
    file_path <- paste0(t, "_", sample, "_matrix.csv")
    if (!file.exists(file_path)) {
      warning(paste("File does not exist:", file_path))
      next
    }
    
    mat <- read.table(file_path, header = FALSE, skip = 1, sep = "\t")
    
    # Remove rows with NA values
    mat <- na.omit(mat)
    
    # Increment counts by 1 to avoid zero values
    mat$V2 <- mat$V2 + 1
    mat$V3 <- mat$V3 + 1
    
    # Filter out rows where the sum of counts is less than or equal to 10
    mat <- mat[(mat$V2 + mat$V3) > 10, ]
    
    # Calculate log2 fold change
    mat$log2FC <- log2(mat$V2 / mat$V3)
    
    # Initialize a vector to store p-values
    pvalue <- c()
    
    # Perform binomial test for each row
    for (i in 1:nrow(mat)) {
      biosum <- binom.test(mat[i, 2], mat[i, 2] + mat[i, 3], 0.5)
      pvalue <- c(pvalue, biosum$p.value)
    }
    
    # Add p-values and log-transformed p-values to the dataframe
    mat$pvalue <- pvalue
    mat$log10Pvalue <- -log10(pvalue)
    
    # Rename columns
    colnames(mat) <- c("peaks", "H1", "H2", "log2FC", "pvalue", "log10Pvalue")
    
    # Classify peaks based on fold change and p-value
    mat$type <- "normal"
    mat[mat$log2FC < -1 & mat$pvalue < 0.05, ]$type <- "down"
    mat[mat$log2FC > 1 & mat$pvalue < 0.05, ]$type <- "up"
    
    # Set cutoffs for fold change and p-value
    FC_cutoff <- log2(2)
    log10_P_Value_cutoff <- -log10(0.05)
    
    # Plot the data
    p <- ggplot(data = mat, aes(x = log2FC, y = log10Pvalue)) +
      geom_point(data = subset(mat, mat$type == "normal"), col = 'gray', alpha = 0.4) +
      geom_point(data = subset(mat, mat$type == "up"), col = 'red', alpha = 0.4) +
      geom_point(data = subset(mat, mat$type == "down"), col = 'blue', alpha = 0.4) +
      theme_bw() +
      theme(legend.title = element_blank(),
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            legend.position = 'none',
            axis.line = element_line(colour = "black")) +
      labs(x = 'log2(fold change)', y = '-log10(p-value)') +
      geom_vline(xintercept = c(-FC_cutoff, FC_cutoff), lty = 3, col = 'black', lwd = 0.4) +
      geom_hline(yintercept = log10_P_Value_cutoff, lty = 3, col = 'black', lwd = 0.4) +
      theme(plot.title = element_text(hjust = 0.5))
    
    # Save the plot as a PDF
    ggsave(p, filename = paste0(t, "_", sample, ".pdf"))
    
    # Filter out normal peaks and save the result to a file
    mat <- mat[mat$type != "normal", ]
    write.table(mat, paste0(t, "_", sample, "_pse.matrix"), row.names = FALSE, col.names = TRUE, sep = "\t", quote = FALSE)
  }
}
