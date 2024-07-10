suppressMessages({
  library("WGCNA")
  library("reshape2")
  library("data.table")
})

# Arg 1: dataset size in MB (100, 500 or 1500)
# Arg 2: number of threads
# Arg 3: metodo (pearson, spearman or kendall)

args <- commandArgs(trailingOnly = TRUE)

dataset = args[[1]]
threads = as.numeric(args[[2]])
metodo = args[[3]]

if(args[[3]] == "single-pearson"){
  metodo = "pearson"
} else if (args[[3]] == "single-kendalls") {
   metodo = "kendall"
} else if (args[[3]] == "single-spearman") {
   metodo = "spearman"
} else {
  cat("args[[3]] should be one of “single-pearson”, “single-kendalls” or “single-spearman”")
}

# Correlation_threshold or r.minimium value
r.minimium=0.5
# Metodo de ajuste del p-valor. Opciones posibles: "bonferroni", "holm", "hochberg", "hommel", "BH" (o su alias "fdr"), "BY"
metodo_ajuste="fdr"
# Numero de correlaciones finales (mejores N resultados luego de aplicar el Correlation_threshold) 
keep_top_n=10

# Utils
readGeneExpressionFile <- function(gene.file, ncol.for.expression.id=1) {
  gene <- na.omit(read.table(gene.file, header=TRUE, fill=TRUE, sep="\t",check.names=F))  
  gene <-SortMatrixByColumnName(gene, 1)
  return (gene)
}  

readMethylationFile <- function(meth.path, ncol.for.expression.id=1) {
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
dataset1.methylation.path<-"opt-1/tests/medium_files/methylation_gene.csv"
dataset2.gene.path<-paste("../datasets/gem-",dataset,"mb.csv", sep="")

# dataset1.methylation.path<-"/home/mauri/Documentos/Multiomix/benchmarks_ggca/datasets/data_methylation_hm27.txt"
# dataset2.gene.path<-"/home/mauri/Documentos/Multiomix/benchmarks_ggca/datasets/data_mrna_seq_v2_rsem_zscores_ref_all_samples.txt"

methyl.dataset <- readMethylationFile(dataset1.methylation.path)
gene.dataset <- readGeneExpressionFile(dataset2.gene.path)

#Keep columns which are in both databases
intersection<-keepSameColumns(methyl.dataset, gene.dataset)
methyl.dataset<-(intersection[[1]])
gene.dataset<-(intersection[[2]])

row.names(methyl.dataset)<-methyl.dataset[,1]
row.names(gene.dataset)<-gene.dataset[,1]
methyl.dataset<-methyl.dataset[,2:ncol(methyl.dataset)]
gene.dataset<-gene.dataset[,2:ncol(gene.dataset)]

### Enable parallel processing for WCGNA Correlation
# unnecessary_output <- capture.output({
#   enableWGCNAThreads(threads)
# })
th = enableWGCNAThreads(threads)

# cat(paste("Dataset", "Algorithm", "Optimization", "Threads", "Finished time (ms)", "Combinations evaluated",sep="\t"), "\n")

# Calcular correlaciones 
ptm <- proc.time()
# Calculate correlation between x and y using  WCGNA
correlation.start <- proc.time()
# transpose matrix before correlation
methyl.dataset.transposed <-t(methyl.dataset)
gene.dataset.transposed <- t(gene.dataset)

methyl.dataset.transposed.numeric <-apply(methyl.dataset.transposed, 2, as.numeric)
gene.dataset.transposed.numeric <-apply(gene.dataset.transposed, 2, as.numeric)

cor.and.pvalue <- corAndPvalue(methyl.dataset.transposed.numeric, gene.dataset.transposed.numeric, method=metodo, nThreads=th)

# obtengo numero de correlaciones calculadas
numCorrelations <- length(cor.and.pvalue$cor)

# correlation result into a dataframe
cor.melt<-reshape2::melt(cor.and.pvalue$cor)
colnames(cor.melt) <- c("x","y","correlation")
# Filter rows with a correlation that does not meet the minimum required value
cor.melt <- subset(cor.melt, abs(correlation) > r.minimium)

# obtengo numero de correlaciones que pasan el umbral seteado
numGoodCorrelations <- length(cor.melt$correlation)

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

# Mantengo en los resultados las mejores N correlaciones
resultado <- result.table[order(-correlation)][1:keep_top_n]

# Tiempo de collelacion y de ajuste:
tiempo_transcurrido = (proc.time() - correlation.start)["elapsed"] * 1000
cat(paste(metodo, "R_WGCNA", threads, tiempo_transcurrido, paste(numGoodCorrelations,"/",numCorrelations, sep="") ,sep="\t"), "\n")