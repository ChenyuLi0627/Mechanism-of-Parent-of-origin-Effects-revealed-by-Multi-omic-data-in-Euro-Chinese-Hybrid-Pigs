args=commandArgs(trailingOnly = T)
data<-read.table(args[1],header=F)
dis<-diff(data$V2)
dis[dis>0&dis<=500]<-1
dis[dis<0|dis>500]<- 0
dis<-c(0,dis)
b <- rev(dis)
startdup <- which(diff(dis)==0)
startdup <- startdup[!(startdup %in% which(dis==0))]
enddup <- which(diff(b)==0)
enddup <- enddup[!(enddup %in% which(b==0))]
enddup <- length(dis)+1 - enddup
dup <- intersect(startdup,enddup)
startdup <- startdup[!(startdup %in% dup)]
enddup <- sort(enddup[!(enddup %in% dup)])
DMR <- cbind(data[startdup,c(1,2)],data[enddup,c(1,2)])
write.table(DMR,paste0(args[2],"_DMR.txt"),row.names = F,col.names = F,quote = F,sep="\t")