suppressMessages({
  library("WGCNA")
  library("reshape2")
  library("data.table")
})

# Arg 1: number of repetitions
# Arg 2: dataset size in MB (100, 500 or 1500)
# Arg 3: number of threads
# Arg 4: metodo (pearson, spearman or kendall)

args <- commandArgs(trailingOnly = TRUE)

repeticiones = as.numeric(args[[1]])
dataset = args[[2]]
threads = as.numeric(args[[3]])
metodo = args[[4]]

if( metodo == "pearson" ){
  metodo_output = "single-pearson"
} else if (metodo == "spearman"){
  metodo_output = "single-spearman"
} else{
  metodo_output = "single-kendalls"
}

# Correlation_threshold or r.minimium value
r.minimium=0.5
# Metodo de ajuste del p-valor. Opciones posibles: "bonferroni", "holm", "hochberg", "hommel", "BH" (o su alias "fdr"), "BY"
metodo_ajuste="fdr"
# Numero de correlaciones finales (mejores N resultados luego de aplicar el Correlation_threshold) 
keep_top_n=10

# Utils
readMirnaExpressionFile <- function(mirna.file, ncol.for.expression.id=1) {
  mirna <- na.omit(read.table(mirna.file, header=TRUE, fill=TRUE, sep="\t",check.names=F))  
  mirna <-SortMatrixByColumnName(mirna, 1)
  return (mirna)
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
dataset2.mirna.path<-paste("../datasets/gem-",dataset,"mb.csv", sep="")

methyl.dataset <- readMethylationFile(dataset1.methylation.path)
mirna.dataset <- readMirnaExpressionFile(dataset2.mirna.path)

#Keep columns which are in both databases
intersection<-keepSameColumns(methyl.dataset, mirna.dataset)
methyl.dataset<-(intersection[[1]])
mirna.dataset<-(intersection[[2]])

row.names(methyl.dataset)<-methyl.dataset[,1]
row.names(mirna.dataset)<-mirna.dataset[,1]
methyl.dataset<-methyl.dataset[,2:ncol(methyl.dataset)]
mirna.dataset<-mirna.dataset[,2:ncol(mirna.dataset)]

### Enable parallel processing for WCGNA Correlation
unnecessary_output <- capture.output({
  enableWGCNAThreads(threads)
})

# cat(paste("Dataset", "Algorithm", "Optimization", "Threads", "Finished time (ms)", "Combinations evaluated",sep="\t"), "\n")

# Calcular correlaciones 
for (rep in 1:repeticiones) {
  ptm <- proc.time()
  # Calculate correlation between x and y using  WCGNA
  correlation.start <- proc.time()
  # transpose matrix before correlation
  methyl.dataset.transposed <-t(methyl.dataset)
  mirna.dataset.transposed <- t(mirna.dataset)

  methyl.dataset.transposed.numeric<-apply(methyl.dataset.transposed, 2, as.numeric)
  mirna.dataset.transposed.numeric<-apply(mirna.dataset.transposed, 2, as.numeric)

  cor.and.pvalue <- corAndPvalue(methyl.dataset.transposed.numeric, mirna.dataset.transposed.numeric, method=metodo)
  
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
  cat(paste(metodo_output, "R_WGCNA", threads, tiempo_transcurrido, paste(numGoodCorrelations,"/",numCorrelations, sep="") ,sep="\t"), "\n")
}