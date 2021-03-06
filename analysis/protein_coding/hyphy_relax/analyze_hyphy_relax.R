setwd("~/Projects/birds/ratite_compgen/ratite-genomics/analysis/protein_coding/hyphy_relax/")
library(data.table)

#ratites
rp<-read.table("relax_pval.all", header=F)
rk<-read.table("relax_K.all", header=F, fill=T)

rp=rp[,c(1,4,5,6,8)]
rk=rk[,c(1,4,5,6,8)]

names(rp)=c("set", "hog", "tree", "type", "pval")
names(rk)=c("set", "hog", "tree", "type", "K")
relax=merge(rp,rk)

relax=subset(relax, pval != "-------" & !is.na(K))
relax$pval=as.numeric(as.character(relax$pval))
relax=unique(relax)

#make hog<->galGal key
hogs<-read.table("/Users/tim/Projects/birds/ratite_compgen/ratite-genomics/homology/new_hog_list.txt")
ncbikey<-read.table("/Users/tim/Projects/birds/ratite_compgen/ratite-genomics/annotation/galGalAnnot/CGNC_Gallus_gallus_20161020.txt", header=F, sep="\t", comment.char="", col.names=c("cgnc", "ncbi", "ensembl", "sym", "descr", "sp"), quote="")
hogs.galgal<-subset(hogs, V4=="galGal")
hogs.galgal$hog=sub("HOG2_","",hogs.galgal$V1,fixed=T)
hogs.galgal<-merge(hogs.galgal, ncbikey, all.x=T, all.y=F, by.x="V3", by.y="ncbi")

#load tree key from paml_ancrec 
ancrec.parsed<-fread("gunzip -c ../paml_ancrec/ancrec_parsed.out.gz")
paml.treekey<-ancrec.parsed[,c("hog", "treenum", "species_tree"), with=FALSE]
paml.treekey$tree = paste0("tree", paml.treekey$treenum)

#add species tree info
relax = merge(relax, paml.treekey, by.x=c("hog", "tree"), by.y=c("hog", "tree"))

#analysis
relax.tips<-subset(relax, species_tree==TRUE & type=="tips")
relax.tips$pval=as.numeric(as.character(relax.tips$pval))
relax.tips$qval=p.adjust(relax.tips$pval, method="fdr")

table(relax.tips$qval < 0.05, relax.tips$set)

#make sig key
relax.tips$sig = as.numeric(relax.tips$qval < 0.05) * sign(1 - relax.tips$K)
#K < 1 is relaxed, K > 1 is accelerated

table(relax.tips$set, relax.tips$sig)

#wide format
relax.tips.wide<-reshape(relax.tips[,c("hog", "set", "sig")], timevar="set", idvar="hog", direction="wide")

table(relax.tips.wide$sig.tinamou, relax.tips.wide$sig.ratite)


relax.tips$Kplot=relax.tips$K
relax.tips$Kplot[relax.tips$K < 0.01] = 0.01
relax.tips$chr=1
relax.tips$chr[relax.tips$K<0.01]=18
plot(log2(relax.tips$Kplot), -log10(relax.tips$pval), col=ifelse(relax.tips$qval<0.05,"red", "black"), xlab="log2(K value from RELAX)", ylab="-log10(p-value)", pch=relax.tips$chr)

#all
relax.all<-subset(relax, tree=="tree1" & type=="all")
relax.all$pval=as.numeric(as.character(relax.all$pval))
relax.all$qval=p.adjust(relax.all$pval, method="fdr")
relax.all$Kplot=relax.all$K
relax.all$Kplot[relax.all$K < 0.01] = 0.01
relax.all$chr=1
relax.all$chr[relax.all$K<0.01]=18
plot(log2(relax.all$Kplot), -log10(relax.all$pval), col=ifelse(relax.all$qval<0.05,"red", "black"), xlab="log2(K value from RELAX)", ylab="-log10(p-value)", pch=relax.all$chr)

#tips hogs
relaxed.hogs<-relax.tips$hog[relax.tips$K<1 & relax.tips$qval<0.05]
acc.hogs<-relax.tips$hog[relax.tips$K>1 & relax.tips$qval<0.05]

#hog->galGal
hogs<-read.table("/Users/tim/Projects/birds/ratite_compgen/ratite-genomics/homology/new_hog_list.txt")
ncbikey<-read.table("~/Downloads/CGNC_Gallus_gallus_20161020.txt", header=F, sep="\t", comment.char="", col.names=c("cgnc", "ncbi", "ensembl", "sym", "descr", "sp"), quote="")
hogs.galgal<-subset(hogs, V4=="galGal")
hogs.galgal$hog=sub("HOG2_","",hogs.galgal$V1,fixed=T)
hogs.galgal<-merge(hogs.galgal, ncbikey, all.x=T, all.y=F, by.x="V3", by.y="ncbi")

relaxed.hogs.galgal<-subset(hogs.galgal, hog %in% relaxed.hogs)
write.table(relaxed.hogs.galgal$sym, file="relaxed.galgal.sym", quote=F, row.names=F, col.names=F)
write.table(relaxed.hogs.galgal$ensembl, file="relaxed.galgal.ens", quote=F, row.names=F, col.names=F)
write.table(relaxed.hogs.galgal$V3, file="relaxed.galgal.ncbi", quote=F, row.names=F, col.names=F)

accel.hogs.galgal<-subset(hogs.galgal, hog %in% acc.hogs)
write.table(accel.hogs.galgal$V3, file="acc.galgal.ncbi", quote=F, row.names=F, col.names=F)
