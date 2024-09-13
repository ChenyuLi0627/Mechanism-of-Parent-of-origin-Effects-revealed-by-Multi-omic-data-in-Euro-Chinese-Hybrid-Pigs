setwd("E:\\Rwork\\cut&tag_formal\\H3K4me3_H3K27ac_H3K27me3_H3K4me1_CTCF")
library(magrittr)
library(dplyr)
library(ggridges)
library(ggplot2)
library(viridis)
library(ggpubr)
library(tidyverse)
sampleList<-c("20101_BF_H3K27ac","20101_BF_H3K4me3",
              "20203_BF_H3K27ac","20203_BF_H3K4me3",
              "5572_BF_H3K27ac","5572_BF_H3K4me3",
              "5814_BF_H3K27ac","5814_BF_H3K4me3",
              "20101_LD_H3K27ac","20101_LD_H3K4me3",
              "20203_LD_H3K27ac","20203_LD_H3K4me3",
              "5572_LD_H3K27ac","5572_LD_H3K4me3",
              "5814_LD_H3K27ac","5814_LD_H3K4me3",
              "M15S1_LD_H3K27ac","M15S1_LD_H3K4me3",
              "20101_BF_H3K27me3","20101_BF_H3K4me1",
              "20101_BF_H3K27me3","20203_BF_H3K4me1",
              "5572_BF_H3K27me3","5572_BF_H3K4me1",
              "5814_BF_H3K27me3","5814_BF_H3K4me1",
              "M15S1_BF_H3K27me3","M15S1_BF_H3K4me1",
              "20101_LD_H3K27me3","20101_LD_H3K4me1",
              "20203_LD_H3K27me3","20203_LD_H3K4me1",
              "5572_LD_H3K27me3","5572_LD_H3K4me1",
              "5814_LD_H3K27me3","5814_LD_H3K4me1",
              "M15S1_LD_H3K27me3","M15S1_LD_H3K4me1",
              "20101_BF_CTCF","20101_LD_CTCF",
              "20203_BF_CTCF","20203_LD_CTCF",
              "5572_BF_CTCF","5572_LD_CTCF",
              "5814_BF_CTCF","5814_LD_CTCF",
              "M15S1_BF_CTCF","M15S1_LD_CTCF")
histList<-c("H3K4me3","H3K27ac","H3K27me3","H3K4me1","CTCF")
####################DRC_reference
alignResult<-data.frame()
for(hist in sampleList){
  alignRes=read.table(paste0(hist,"_bowtie2.txt"),header = F,fill = T)
  alignRate=substr(alignRes$V1[6],1,nchar(as.character(alignRes$V1[6]))-1)
  tmp=data.frame(         Histone=unlist(strsplit(hist,"_"))[3]%>%as.character,
                          Tissue=unlist(strsplit(hist,"_"))[2]%>%as.character,
                          Replicate=unlist(strsplit(hist,"_"))[c(1)]%>%as.character,
                          SequencingDepth=alignRes$V1[1]%>%as.character%>%as.numeric,
                          MappedFragNum_DRC=alignRes$V1[1]%>%as.character%>%as.numeric-alignRes$V1[3]%>%as.character%>%as.numeric,
                          AlignmentRate_DRC= alignRate%>%as.numeric)
  alignResult<-rbind(alignResult,tmp) 
}

alignResult$Histone<-factor(alignResult$Histone,levels=histList)
##########plot_seqencing_depth
fig3A =alignResult%>% ggplot(aes(x = Histone, y = SequencingDepth/1000000, fill = Histone)) +
  geom_boxplot() +
  geom_jitter(aes(color = Replicate), position = position_jitter(0.15)) +
  scale_fill_viridis(discrete = TRUE, begin = 0.1, end = 0.9, option = "magma", alpha = 0.8) +
  scale_color_viridis(discrete = TRUE, begin = 0.1, end = 0.9) +
  theme_bw(base_size = 18) +
  ylab("Sequencing Depth per Million") +
  xlab("") +
  ggtitle("A. Sequencing Depth")
fig3B = alignResult %>% ggplot(aes(x = Histone, y = MappedFragNum_DRC/1000000, fill = Histone)) +
  geom_boxplot() +
  geom_jitter(aes(color = Replicate), position = position_jitter(0.15)) +
  scale_fill_viridis(discrete = TRUE, begin = 0.1, end = 0.9, option = "magma", alpha = 0.8) +
  scale_color_viridis(discrete = TRUE, begin = 0.1, end = 0.9) +
  theme_bw(base_size = 18) +
  ylab("Mapped Fragments per Million") +
  xlab("") +
  ggtitle("B. Alignable Fragment (11.1)")
fig3C = alignResult %>% ggplot(aes(x = Histone, y = AlignmentRate_DRC, fill = Histone)) +
  geom_boxplot() +
  geom_jitter(aes(color = Replicate), position = position_jitter(0.15)) +
  scale_fill_viridis(discrete = TRUE, begin = 0.1, end = 0.9, option = "magma", alpha = 0.8) +
  scale_color_viridis(discrete = TRUE, begin = 0.1, end = 0.9) +
  theme_bw(base_size = 18) +
  ylab("% of Mapped Fragments") +
  xlab("") +
  ggtitle("C. Alignment Rate (11.1)")
pdf("seqencing_depth.pdf",width = 10,height = 8)
ggarrange(fig3A,fig3B,fig3C,ncol = 2,nrow = 2,common.legend = T,legend = "bottom")
dev.off()

dupResult<-data.frame()
for(hist in sampleList){
  dupRes=read.table(paste0(hist,"_picard.rmDup.txt"),header = T,fill = T)
  histInfo=strsplit(hist,"_")[[1]]
  tmp2=data.frame(Histone=histInfo[3],
                  Replicate=histInfo[1],
                  Tissue=histInfo[2],
                  MappedFragNum_hg38=dupRes$READ_PAIRS_EXAMINED[1]%>%as.character%>%as.numeric,
                  DuplicationRate=dupRes$PERCENT_DUPLICATION[1]%>%as.character%>%as.numeric*100,
                  EstimatedLibrarySize=dupRes$ESTIMATED_LIBRARY_SIZE%>%as.character%>%as.numeric
  )[1,]
  tmp2$UniqueFragNum=tmp2$MappedFragNum_hg38*(1-tmp2$DuplicationRate/100)
  dupResult<-rbind(dupResult,tmp2)
}
dupResult$Histone<-factor(dupResult$Histone,levels=histList)
#############plot_duplication
m = substr(dupResult$DuplicationRate,1,6)
m = as.numeric(m)
fig4A = dupResult %>% ggplot(aes(x = Histone, y = m, fill = Histone)) +
  geom_boxplot() +
  geom_jitter(aes(color = Replicate), position = position_jitter(0.15)) +
  scale_fill_viridis(discrete = TRUE, begin = 0.1, end = 0.9, option = "magma", alpha = 0.8) +
  scale_color_viridis(discrete = TRUE, begin = 0.1, end = 0.9) +
  theme_bw(base_size = 18) +
  ylab("Duplication Rate (*100%)") +
  xlab("")
fig4B = dupResult %>% ggplot(aes(x = Histone, y = EstimatedLibrarySize, fill = Histone)) +
  geom_boxplot() +
  geom_jitter(aes(color = Replicate), position = position_jitter(0.15)) +
  scale_fill_viridis(discrete = TRUE, begin = 0.1, end = 0.9, option = "magma", alpha = 0.8) +
  scale_color_viridis(discrete = TRUE, begin = 0.1, end = 0.9) +
  theme_bw(base_size = 16) +
  ylab("Estimated Library Size") +
  xlab("")
fig4C = dupResult %>% ggplot(aes(x = Histone, y = UniqueFragNum, fill = Histone)) +
  geom_boxplot() +
  geom_jitter(aes(color = Replicate), position = position_jitter(0.15)) +
  scale_fill_viridis(discrete = TRUE, begin = 0.1, end = 0.9, option = "magma", alpha = 0.8) +
  scale_color_viridis(discrete = TRUE, begin = 0.1, end = 0.9) +
  theme_bw(base_size = 16) +
  ylab("# of Unique Fragments") +
  xlab("")
pdf("plot_duplication.pdf",width = 10,height = 8)
ggarrange(fig4A,fig4B,fig4C,ncol = 3,nrow = 1,common.legend = T,legend = "bottom")
dev.off()
alignSummary=left_join(alignResult,dupResult,by=c("Histone","Replicate","Tissue"))
###########################fragmentLen###################################
fragLenResult<-data.frame()
for(hist in sampleList){
  fragLenRes=read.table(paste0(hist,"_fragmentLen.txt"),header = F,fill = T)
  histInfo=strsplit(hist,"_")[[1]]
  tmp3=data.frame(Histone=histInfo[3],
                  Replicate=histInfo[1],
                  Tissue=histInfo[2],
                  fragLen=fragLenRes$V1%>%as.numeric,
                  fragCount=fragLenRes$V2%>%as.numeric,
                  Weight=as.numeric(fragLenRes$V2)/sum(as.numeric(fragLenRes$V2)),
                  sampleInfo=hist
  )
  fragLenResult<-rbind(fragLenResult,tmp3)
}

fragLenResult$sampleInfo=factor(fragLenResult$sampleInfo,levels=sampleList)
fragLenResult$Histone=factor(fragLenResult$Histone,levels = histList)
###############plot_distribution
fig5A = fragLenResult %>% ggplot(aes(x = sampleInfo, y = fragLen, weight = Weight, fill = Histone))+
  geom_violin(bw = 5) +
  scale_y_continuous(breaks = seq(0, 800, 50)) +
  scale_fill_viridis(discrete = TRUE, begin = 0.1, end = 0.9, option = "magma", alpha = 0.8) +
  scale_color_viridis(discrete = TRUE, begin = 0.1, end = 0.9) +
  theme_bw(base_size = 20) +
  ggpubr::rotate_x_text(angle = 30) +
  ylab("Fragment Length") +
  xlab("")
fig5B = fragLenResult %>% ggplot(aes(x = fragLen, y = fragCount, color = Histone, group = sampleInfo,linetype=Replicate))+ ###在有生物学重复的时候用Replicate
  geom_line(size = 1) +
  scale_color_viridis(discrete = TRUE, begin = 0.1, end = 0.9, option = "magma") +
  theme_bw(base_size = 20) +
  xlab("Fragment Length") +
  ylab("Count") +
  coord_cartesian(xlim = c(0, 500))
pdf("plot_distribution.pdf",width = 18,height = 8)
ggarrange(fig5A, fig5B, ncol = 2)
dev.off()