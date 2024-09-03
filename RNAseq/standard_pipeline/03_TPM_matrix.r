setwd("E:\\Rwork2024\\expand_five_RNAseq\\TPM_expression_cor_six_tissues")
library(tidyverse)
library(pheatmap)
library(magrittr)
library(RColorBrewer)
# Load necessary library
library(data.table)

# Define the directory where your files are located
directory <- "E:\\Rwork2024\\expand_five_RNAseq\\TPM_expression_cor_six_tissues" # replace with your directory path

# List all files in the directory
files <- list.files(directory, pattern="*.TPM", full.names=TRUE)

# Initialize an empty data.table
merged_data <- NULL

# Loop through each file and merge the data incrementally
for (file in files) {
  # Read the file as data.table
  data <- fread(file, header = T, sep = "\t")
  
  # Extract file prefix as column name
  file_prefix <- tools::file_path_sans_ext(basename(file))
  
  # Set column names as "Gene" and the file prefix
  setnames(data, old = colnames(data), new = c("Gene", file_prefix))
  
  # Remove duplicate Gene names within the same file
  data <- data[!duplicated(data$Gene), ]
  
  # Merge with the existing data
  if (is.null(merged_data)) {
    merged_data <- data
  } else {
    merged_data <- merge(merged_data, data, by = "Gene", all = TRUE, allow.cartesian = TRUE)
  }
  
  # Free up memory
  rm(data)
  gc()
}

# Replace NA values with 0
merged_data[is.na(merged_data)] <- 0

# Save the merged data to a new file
fwrite(merged_data, "merged_TPM_matrix.txt", sep="\t", quote=FALSE)
m<-as.matrix(merged_data[,-1])
M<-cor(m,method = "spearman")
fwrite(as.data.frame(M), "TPM_cor_matrix.txt", sep="\t", quote=FALSE,col.names = T,row.names = T)




#################################################################### Load necessary libraries
library(pheatmap)
library(RColorBrewer)
pdf("EXP_pearson_heatmap.pdf",height = 8,width=10)
# Load your data
data <- read.table("TPM_cor_matrix.txt", header = TRUE, row.names = 1)

# Define RowCluster annotation based on the presence of specific keywords in row names
ann_row1 <- data.frame(
  Tissues = ifelse(grepl("BF", rownames(data), ignore.case = TRUE), "BF",
                      ifelse(grepl("RAD", rownames(data), ignore.case = TRUE), "RAD",
                             ifelse(grepl("MAD", rownames(data), ignore.case = TRUE), "MAD",
                                    ifelse(grepl("GOM", rownames(data), ignore.case = TRUE), "GOM",
                                           ifelse(grepl("LDM", rownames(data), ignore.case = TRUE), "LDM",
                                                  ifelse(grepl("PM", rownames(data), ignore.case = TRUE), "PM", NA))))))
)
rownames(ann_row1) <- rownames(data)

# Define TissueType annotation based on the presence of BF, RAD, MAD, GOM (Fat) or LDM, PM (Muscle)
ann_row2 <- data.frame(
  TissueCluster = ifelse(grepl("BF|RAD|MAD|GOM", rownames(data), ignore.case = TRUE), "Adipose",
                      ifelse(grepl("LDM|PM", rownames(data), ignore.case = TRUE), "Skeletal Muscle", NA))
)
rownames(ann_row2) <- rownames(data)

# Remove rows with NA values from the annotations
anno_row <- cbind(ann_row1, ann_row2)
anno_row <- anno_row[complete.cases(anno_row), ]

# Filter the data to match the annotations
data_filtered <- data[rownames(anno_row), ]

# Define color palette for annotations
ann_colors <- list(
  Tissues = c(BF = "#D68B4D", RAD = "#EF7A7B", MAD = "#D3DD75", GOM = "#FFDDB4", LDM = "#1B9BC0", PM = "#6F79BC"),
  TissueCluster = c("Adipose" = "#CD3310", "Skeletal Muscle" = "#31BAEE")
)

# Create the heatmap with row annotations only, no column clustering, and no borders
pheatmap(
  data_filtered, 
  annotation_row = anno_row, 
  annotation_colors = ann_colors,
  show_rownames = TRUE, 
  show_colnames = TRUE,
  cluster_rows = TRUE, 
  cluster_cols = TRUE, # Disable column clustering
  scale = "none", # Scaling by row, can be changed to "none" or "column"
  color = colorRampPalette(rev(brewer.pal(n = 7, name = "RdYlBu")))(100),
  border_color = NA # Remove all borders
)
dev.off()

