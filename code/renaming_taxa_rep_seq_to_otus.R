library(reshape2)

args<-commandArgs(TRUE)

taxa<-read.delim(args[1], sep='\t', header=T, row.names=1)
repseq<-rownames(taxa)
tax_table<-cbind(repseq, taxa[, 1:length(taxa[1, ])])

otu_map<-read.delim(args[2], sep='\t', header=F)
names(otu_map)<-c("OTUS", "repseq")

out<-merge(otu_map, tax_table, "repseq")

write.table(out, file=args[3], sep='\t', quote=F, row.names=F)
