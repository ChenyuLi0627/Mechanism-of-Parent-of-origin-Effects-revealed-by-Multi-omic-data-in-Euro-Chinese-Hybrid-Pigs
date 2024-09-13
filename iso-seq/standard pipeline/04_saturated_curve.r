library(ggplot2)
reall.gene=read.table("sample.rarefaction.by_refgene.min_fl_2.txt",header=T,sep=' ',skip=1)  ##file generated in the previous step
reall.iso=read.table("sample.rarefaction.by_refisoform.min_fl_2.txt",header=T,sep=' ',skip=1) ##file generated in the previous step

df <- data.frame(size=reall.gene$size, mean=reall.gene$mean, type='reGene')
df <- rbind(df, data.frame(size=reall.iso$size, mean=reall.iso$mean, type='reIsoform'))

View(df)
p <- ggplot(df, aes(x=size, y=mean, color=type)) + geom_line(lwd=1.2)
p <- p + theme_classic()
p <- p + theme(axis.text.x=element_text(face="bold",color="black",size=15),
               axis.text.y=element_text(face = "bold",size = 15),
               axis.title.x=element_text(size = 15,face = "bold"),
               axis.title.y=element_text(size = 15,face = "bold"))
p <- p + theme(axis.line.x=element_line(colour = "black"),axis.line.y=element_line(colour = "black"),
               legend.key.height=unit(1,"cm"),
               legend.key.width=unit(1,"cm"),
               legend.text=element_text(lineheight=0.8,face="bold",size=15),
               legend.title=element_text(size=15,face="bold"))
p<- p + xlab("Number of Subsampled Reads") + ylab("Number of Detected Genes/Isoforms") + labs(title="Rarefaction, Gene or Isoform Level")+theme(title=element_text(size = 15,face = "bold"))
p