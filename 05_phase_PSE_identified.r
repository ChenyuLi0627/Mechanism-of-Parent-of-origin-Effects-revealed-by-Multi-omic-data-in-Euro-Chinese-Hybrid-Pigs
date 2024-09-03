setwd("E:\\Rwork2024\\expand_five_RNAseq\\PSE_identified_six_tissues")
# Load necessary library
library(ggplot2)

# Define tissue types and samples
tissue <- c("GOM", "PM","RAD","MAD","RAD","BF","LDM")
tissue <- c("LDM")
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


library(data.table)
library(dbplyr)
directory <- "E:\\Rwork2024\\expand_five_RNAseq\\PSE_identified_six_tissues" # replace with your directory path

# List all files in the directory
files <- list.files(directory, pattern="*_pse.matrix", full.names=TRUE)

# Initialize an empty data.table
merged_data <- NULL

# Loop through each file and merge the data incrementally
for (file in files) {
  # Read the file as data.table
  data <- fread(file, header = T, sep = "\t")
  data<-data[,c(1,7)]
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
rownames(merged_data)<-merged_data$Gene
fwrite(as.data.frame(M), "PSE_six_tissue_matrix.txt", sep="\t", quote=FALSE,col.names = T,row.names = T)
###########################################################################################################
##多组织的保守PSE和印迹################
library(pheatmap)
merged_data<-read.table("PSE_six_tissue_matrix.txt",header = T)
column_order <- c("BF_20101_pse","BF_20203_pse","BF_5572_pse","BF_5814_pse","BF_M15S1_pse","BF_M15S2_pse",
                  "GOM_20101_pse","GOM_20203_pse","GOM_5572_pse","GOM_5814_pse","GOM_M15S1_pse",
                  "MAD_20101_pse","MAD_20203_pse","MAD_5572_pse","MAD_5814_pse","MAD_M15S1_pse",
                  "RAD_20101_pse","RAD_20203_pse","RAD_5572_pse","RAD_5814_pse","RAD_M15S1_pse",
                  "LDM_20101_pse","LDM_20203_pse","LDM_5572_pse","LDM_5814_pse","LDM_M15S1_pse","LDM_M15S2_pse",
                  "PM_20101_pse","PM_20203_pse","PM_5572_pse","PM_5814_pse","PM_M15S1_pse")

# 根据列名中包含的关键字进行排序
new_order <- order(factor(colnames(df), levels = column_order, ordered = TRUE))

# 重新排列列的顺序
merged_data <- merged_data[, new_order]
M<-as.matrix(merged_data)
M[is.na(M)] <- 0
M[M == "up"] <- 1
M[M == "down"] <- -1
M<-apply(M,2,as.numeric)
row.names(M)<-row.names(merged_data)

nonzero_counts <- rowSums(M != 0)
threshold <- 16
M_filter <- M[nonzero_counts >= threshold & nonzero_counts== abs(rowSums(M)) , ]
row_sums <- rowSums(M_filter)

# 根据每一行的和进行降序排序
M_filter_sort <- M_filter[order(-row_sums), ]
fwrite(as.data.frame(M_filter_sort), "conversed_PSE_six_tissue_matrix.txt", sep="\t", quote=FALSE,col.names = T,row.names = T)
ann_col <- data.frame(
  Tissues = ifelse(grepl("BF", colnames(M_filter_sort), ignore.case = TRUE), "BF",
                   ifelse(grepl("RAD", colnames(M_filter_sort), ignore.case = TRUE), "RAD",
                          ifelse(grepl("MAD", colnames(M_filter_sort), ignore.case = TRUE), "MAD",
                                 ifelse(grepl("GOM", colnames(M_filter_sort), ignore.case = TRUE), "GOM",
                                        ifelse(grepl("LDM", colnames(M_filter_sort), ignore.case = TRUE), "LDM",
                                               ifelse(grepl("PM", colnames(M_filter_sort), ignore.case = TRUE), "PM", NA))))))
)
rownames(ann_col)<-colnames(M_filter_sort)
ann_colors <- list(Tissues = c(BF = "#D68B4D", RAD = "#EF7A7B", MAD = "#D3DD75", GOM = "#FFDDB4", LDM = "#1B9BC0", PM = "#6F79BC"))
p1<-pheatmap(
  M_filter_sort, 
  annotation_col = ann_col, 
  annotation_colors = ann_colors,
  show_rownames = T, 
  show_colnames = F,
  cluster_rows = F, 
  cluster_cols = F, # Disable column clustering
  scale = "none", 
  border_color = NA,
  color = colorRampPalette(c("#4e6691", "grey", "#b8474d"))(50)
)
add.flag <- function(pheatmap,
                     kept.labels,
                     repel.degree) {
  
  # repel.degree = number within [0, 1], which controls how much 
  # space to allocate for repelling labels.
  ## repel.degree = 0: spread out labels over existing range of kept labels
  ## repel.degree = 1: spread out labels over the full y-axis
  
  heatmap <- pheatmap$gtable
  
  new.label <- heatmap$grobs[[which(heatmap$layout$name == "row_names")]] 
  
  # keep only labels in kept.labels, replace the rest with ""
  new.label$label <- ifelse(new.label$label %in% kept.labels, 
                            new.label$label, "")
  
  # calculate evenly spaced out y-axis positions
  repelled.y <- function(d, d.select, k = repel.degree){
    # d = vector of distances for labels
    # d.select = vector of T/F for which labels are significant
    
    # recursive function to get current label positions
    # (note the unit is "npc" for all components of each distance)
    strip.npc <- function(dd){
      if(!"unit.arithmetic" %in% class(dd)) {
        return(as.numeric(dd))
      }
      
      d1 <- strip.npc(dd$arg1)
      d2 <- strip.npc(dd$arg2)
      fn <- dd$fname
      return(lazyeval::lazy_eval(paste(d1, fn, d2)))
    }
    
    full.range <- sapply(seq_along(d), function(i) strip.npc(d[i]))
    selected.range <- sapply(seq_along(d[d.select]), function(i) strip.npc(d[d.select][i]))
    
    return(unit(seq(from = max(selected.range) + k*(max(full.range) - max(selected.range)),
                    to = min(selected.range) - k*(min(selected.range) - min(full.range)), 
                    length.out = sum(d.select)), 
                "npc"))
  }
  new.y.positions <- repelled.y(new.label$y,
                                d.select = new.label$label != "")
  new.flag <- segmentsGrob(x0 = new.label$x,
                           x1 = new.label$x + unit(0.15, "npc"),
                           y0 = new.label$y[new.label$label != ""],
                           y1 = new.y.positions)
  
  # shift position for selected labels
  new.label$x <- new.label$x + unit(0.2, "npc")
  new.label$y[new.label$label != ""] <- new.y.positions
  
  # add flag to heatmap
  heatmap <- gtable::gtable_add_grob(x = heatmap,
                                     grobs = new.flag,
                                     t = 4, 
                                     l = 4
  )
  
  # replace label positions in heatmap
  heatmap$grobs[[which(heatmap$layout$name == "row_names")]] <- new.label
  
  # plot result
  grid.newpage()
  grid.draw(heatmap)
  
  # return a copy of the heatmap invisibly
  invisible(heatmap)
}
imprint<-read.table("pigImprintGene.name",head=F)
library(grid)
pdf("PSE_six_tissue_matrix.pdf")
(gene_name<-rownames(M_filter_sort)[rownames(M_filter_sort)%in%imprint$V1])
add.flag(p1,
         kept.labels = gene_name,
         repel.degree = 0.2)
dev.off()