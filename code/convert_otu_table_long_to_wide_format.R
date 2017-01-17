library(reshape2)

args<-commandArgs(TRUE)

data.long<-read.delim(args[1], sep='\t', header=F)
names(data.long) <- c("OTUS", "SAMPLES", "ABUNDANCE")

## output otus as rows, samples as columns
data.wide<-dcast(data.long, OTUS ~ SAMPLES, value.var="ABUNDANCE", fill=0)

#cat("# of otus ~ # of samples: ", dim(data.wide))
#cat("total # of sequences: ", sum(data.wide))
 
write.table(data.wide, args[2], sep='\t', quote=F, row.names=F)
