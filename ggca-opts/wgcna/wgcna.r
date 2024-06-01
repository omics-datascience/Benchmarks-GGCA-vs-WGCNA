library("WGCNA")
library("reshape2")
library("data.table")

# Arg 1: number of repetitions
# Arg 2: dataset size in MB (100, 500 or 1500)
# Arg 3: number of threads
# Arg 4: metodo (pearson, spearman or kendall)

args <- commandArgs(trailingOnly = TRUE)

repeticiones = as.numeric(args[[1]])
dataset = args[[2]]
threads = as.numeric(args[[3]])
metodo = args[[4]]

# Correlation_threshold or r.minimium value
r.minimium=0.7
# Metodo de ajuste del p-valor. Opciones posibles: "bonferroni", "holm", "hochberg", "hommel", "BH" (o su alias "fdr"), "BY"
metodo_ajuste="fdr"

# Utils
readMirnaExpressionFile <- function(mirna.file, ncol.for.expression.id=1) {
  print("Reading the mirna file...")
  mirna <- na.omit(read.table(mirna.file, header=TRUE, fill=TRUE, sep="\t",check.names=F))  
  print("Sorting the mirna data...")
  mirna <-SortMatrixByColumnName(mirna, 1)
  return (mirna)
}  

readMethylationFile <- function(meth.path, ncol.for.expression.id=1) {
  print("Reading methylation file...")
  meth <- na.omit(read.table(meth.path, header=TRUE,fill=TRUE, row.names = NULL, sep="\t", check.names=F))
  meth <-SortMatrixByColumnName(meth, 1)
  return (meth)
}

keepSameColumns <- function(matrix1, matrix2) {
  cols_to_keep <- intersect(colnames(matrix1)[-1],colnames(matrix2)[-1])
  matrix1 <- matrix1[,c(colnames(matrix1)[1],cols_to_keep), drop=FALSE]
  matrix2 <- matrix2[,c(colnames(matrix2)[1],cols_to_keep), drop=FALSE]
  return (list(matrix1,matrix2))
  
}

SortMatrixByColumnName <- function(x, colsToExclude=0){
	return (x[,union(c(1), order(colnames(x)[2:length(colnames(x))])+1)])	
}

# Carga datasets
dataset1.methylation.path<-"../opt-1/tests/medium_files/methylation_gene.csv"
dataset2.mirna.path<-paste("../../datasets/gem-",dataset,"mb.csv", sep="")

methyl.dataset <- readMethylationFile(dataset1.methylation.path)
mirna.dataset <- readMirnaExpressionFile(dataset2.mirna.path)

#Keep columns which are in both databases
intersection<-keepSameColumns(methyl.dataset, mirna.dataset)
methyl.dataset<-(intersection[[1]])
mirna.dataset<-(intersection[[2]])

# 1 - Calculate Correlations Using WCGNA 
  
ptm <- proc.time()

row.names(methyl.dataset)<-methyl.dataset[,1]
row.names(mirna.dataset)<-mirna.dataset[,1]
methyl.dataset<-methyl.dataset[,2:ncol(methyl.dataset)]
mirna.dataset<-mirna.dataset[,2:ncol(mirna.dataset)]

### Enable parallel processing for WCGNA Correlation
enableWGCNAThreads(threads)

# Calculate correlation between x and y using  WCGNA
correlation.start <- proc.time()
# transpose matrix before correlation
methyl.dataset.transposed <-t(methyl.dataset)
mirna.dataset.transposed <- t(mirna.dataset)

methyl.dataset.transposed.numeric<-apply(methyl.dataset.transposed, 2, as.numeric)
mirna.dataset.transposed.numeric<-apply(mirna.dataset.transposed, 2, as.numeric)

cor.and.pvalue <- corAndPvalue(methyl.dataset.transposed.numeric, mirna.dataset.transposed.numeric, method=metodo)

# correlation result into a dataframe
cor.melt<-reshape2::melt(cor.and.pvalue$cor)
colnames(cor.melt) <- c("x","y","correlation")
# Filter rows with a correlation that does not meet the minimum required value
cor.melt <- subset(cor.melt, abs(correlation) > r.minimium)


#pvalue result into a dataframe
p.melt<-reshape2::melt(cor.and.pvalue$p)
colnames(p.melt) <- c("x","y","p.value")

padj.melt<-p.melt
all.p.values<-p.melt[,3]
padj.melt[,3] = p.adjust(all.p.values, length(all.p.values), method = metodo_ajuste)
colnames(padj.melt) <- c("x","y", paste("p.value.",metodo_ajuste,".adjusted",sep=""))

# Merge all three previos tables into a single dataframe.
# Transform data.frame's to data.table's to improve merge performance. Once the merge is done, transform back to data.frame,
# as the caller code needs a data.frame to work
temp.table <- merge(as.data.table(cor.melt), as.data.table(p.melt), by=c("x","y"))
result.table <-merge(temp.table, as.data.table(padj.melt),  by=c("x","y"))

#colnames(result.table)<-(c("Gen_symbol","mature_mirna_id","Mirna_Mrna_Correlation","p_value_Of_Mirna_Mrna_Correlation", "p_value_fdr_adjustedMirna_Mrna_Correlation"))
resultado = as.matrix(result.table)

# Tiempo de collelacion y de ajuste:
cat(paste("Dataset", "Algorithm", "Optimization", "Threads", "Finished time (ms)", "Combinations evaluated",sep="\t"), "\n")
tiempo_transcurrido = (proc.time() - correlation.start)["elapsed"] * 1000
cat(paste(dataset, metodo, "NA", threads, tiempo_transcurrido, "NA" ,sep="\t"), "\n")


# 2 - keep Best Correlations

# best <- keepBestGeneXMirnaAccordingCorrelationAndAddMirnaDbInfo(genes.x.mirnas, working.path, 
#                                                         output.file=just.betters.maturemirna.X.mrna.considering.mirna.databases,
#                                                         predicted.cut.off=my.predicted.cut.off)
# 
# keepBestGeneXMirnaAccordingCorrelationAndAddMirnaDbInfo <- function(genes.x.mirnas, predicted.cut.off=30){
#   
#   print("Running multiMiR analisys")
#   
#   mirnas<-genes.x.mirnas[,2]
#   mirnas<-unique(as.character(mirnas))
#   
#   genes<-genes.x.mirnas[,1]
#   genes<-unique(as.character(genes))
#   
#   #result <- data.frame(Gene_Symbol=character(0), mature_mirna_id=character(0), Mirna_Mrna_Correlation=numeric(0), p_value_Of_Mirna_Mrna_Correlation=numeric(0), Database=character(0),Database_Predicted_Score=numeric(0),pubMedID=character(0))  
#   result <- data.frame(Gene_Symbol=character(0), mature_mirna_id=character(0), Mirna_Mrna_Correlation=numeric(0), p_value_Of_Mirna_Mrna_Correlation=numeric(0), p_value_Of_Mirna_Mrna_Correlation_adjusted=numeric(0), id=numeric(0),Database=character(0),Database_Predicted_Score=numeric(0),pubMedID=character(0))  
#   for (i in 1:length(mirnas)) {
#     
#     print(paste("mirna",i, "/", length(mirnas), ": ", mirnas[i]), sep="")
#     multimir<- getPredictedFromMulimir(mirnas[i])
#     
#     if (!is.null(multimir) && nrow(multimir)>0)
#     {resultTemp<-merge(genes.x.mirnas, multimir,  by.x=c(colnames(genes.x.mirnas)[1],colnames(genes.x.mirnas)[2]),by.y=c("target_symbol", "mature_mirna_id"))
#     result<-rbind(result, resultTemp)
#     }
#   }
# 
#   return (result)
# }
