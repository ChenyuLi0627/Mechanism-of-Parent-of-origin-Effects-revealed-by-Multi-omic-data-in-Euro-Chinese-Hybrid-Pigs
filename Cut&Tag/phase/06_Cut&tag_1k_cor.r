data<-read.table("merged_output.txt",header=T)
coverage_to_TPM <- function(coverage_matrix) { 
                               total_reads <- colSums(coverage_matrix)
                               TPM <- sweep(coverage_matrix, 2, total_reads, FUN="/") * 1e6 
                               return(TPM) 
}
TPM_matrix <- coverage_to_TPM(data)
M<-cor(TPM_matrix,method = "pearson")
write.table(M,"cuttag_cor_pearson.txt",col.names = T,row.names = T,quote = F)
########################################################
setwd("E:\\Rwork2024")
library(pheatmap)
data<-read.table("cuttag_cor_pearson.txt",header = T,row.names = 1)
data<-as.matrix(data)
ann_row1 <- data.frame(
  Assay = ifelse(grepl("H3K27me3", rownames(data), ignore.case = TRUE), "H3K27me3",
                   ifelse(grepl("H3K27ac", rownames(data), ignore.case = TRUE), "H3K27ac",
                          ifelse(grepl("H3K4me3", rownames(data), ignore.case = TRUE), "H3K4me3",
                                 ifelse(grepl("CTCF", rownames(data), ignore.case = TRUE), "CTCF",
                                        ifelse(grepl("H3K4me1", rownames(data), ignore.case = TRUE), "H3K4me1",NA))))))
rownames(ann_row1) <- rownames(data)
ann_row2 <- data.frame(
  Tissue = ifelse(grepl("BF", rownames(data), ignore.case = TRUE), "BF",
                         ifelse(grepl("LD", rownames(data), ignore.case = TRUE), "LD", NA))
)
rownames(ann_row2) <- rownames(data)
ann_row <- cbind(ann_row1, ann_row2)
ann_row <- ann_row[complete.cases(ann_row), ]

ann_colors <- list(Assay = c("H3K27me3" = "#CEB189", "H3K27ac" = "#F4A01C", "H3K4me3" = "#22A9A1", "CTCF" = "#E19277", "H3K4me1" = "#846EB0"),
                   Tissue=c("BF"="#D68B4D","LD"="#1B9BC0"))
pdf("Cut&tag_cor.pdf")
pheatmap(
  data, 
  annotation_row = ann_row, 
  annotation_colors = ann_colors,
  show_rownames = F,
  show_colnames = F,
  cluster_rows = T, 
  cluster_cols = T, # Disable column clustering
  scale = "none", 
  border_color = NA
)
dev.off()