suppressMessages({
  library("WGCNA")
  library("reshape2")
  library("data.table")
})

# Arg 1: metodo (single-pearson, single-spearman or single-kendall)
# Arg 2: number of threads
# Arg 3: dataset GEM
# Arg 4: dataset GENE

args <- commandArgs(trailingOnly = TRUE)

metodo = 'spearman'
threads = 8
dataset1.gem.path = "/home/mauri/Documentos/Multiomix/benchmarks_ggca/datasets/HumanMethylation450_procesado-1mb.tsv"
dataset2.gene.path = "/home/mauri/Documentos/Multiomix/benchmarks_ggca/datasets/HiSeqV2_PANCAN_procesado-5mb.tsv"
# metodo = args[[1]]
# threads = as.numeric(args[[2]])
# dataset1.gem.path = args[[3]]
# dataset2.gene.path = args[[4]]


# if(args[[1]] == "single-pearson"){
#   metodo = "pearson"
# } else if (args[[1]] == "single-kendalls") {
#    metodo = "kendall"
# } else if (args[[1]] == "single-spearman") {
#    metodo = "spearman"
# } else {
#   cat("args[[1]] should be one of “single-pearson”, “single-kendalls” or “single-spearman”")
# }

# Correlation_threshold or r.minimium value
r.minimium=0.5
# Metodo de ajuste del p-valor. Opciones posibles: "bonferroni", "holm", "hochberg", "hommel", "BH" (o su alias "fdr"), "BY"
metodo_ajuste="fdr"
# Numero de correlaciones finales (mejores N resultados luego de aplicar el Correlation_threshold) 
keep_top_n=10

# Utils
readFile <- function(file_path) {
  file <- na.omit(read.table(file_path, header=TRUE,fill=TRUE, row.names = NULL, sep="\t", check.names=F))
  file <-SortMatrixByColumnName(file, 1)
  return (file)
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

gem.dataset <- readFile(dataset1.gem.path)
gene.dataset <- readFile(dataset2.gene.path)

#Keep columns which are in both databases
intersection<-keepSameColumns(gem.dataset, gene.dataset)
gem.dataset<-(intersection[[1]])
gene.dataset<-(intersection[[2]])

row.names(gem.dataset)<-gem.dataset[,1]
row.names(gene.dataset)<-gene.dataset[,1]
gem.dataset<-gem.dataset[,2:ncol(gem.dataset)]
gene.dataset<-gene.dataset[,2:ncol(gene.dataset)]

### Enable parallel processing for WCGNA Correlation
unnecessary_output <- capture.output({
  th = enableWGCNAThreads(threads)
})

# cat(paste("Dataset", "Algorithm", "Optimization", "Threads", "Finished time (ms)", "Combinations evaluated",sep="\t"), "\n")

# result <- tryCatch({
  # Calcular correlaciones 
  ptm <- proc.time()
  # Calculate correlation between x and y using  WCGNA
  correlation.start <- proc.time()
  # transpose matrix before correlation
  gem.dataset.transposed <-t(gem.dataset)
  gene.dataset.transposed <- t(gene.dataset)

  gem.dataset.transposed.numeric <-apply(gem.dataset.transposed, 2, as.numeric)
  gene.dataset.transposed.numeric <-apply(gene.dataset.transposed, 2, as.numeric)

  
  cat("comienza correlacion...")  
  cor.and.pvalue <- corAndPvalue(gem.dataset.transposed.numeric, gene.dataset.transposed.numeric, method=metodo, nThreads=th)
  cat("finaliza correlacion...")
  # obtengo numero de correlaciones calculadas
  # numCorrelations <- length(cor.and.pvalue$cor)
  numCorrelations <- length(cor.and.pvalue$p[!is.na(cor.and.pvalue$p)])
  
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
  cat(paste(metodo, "wgcna_R", threads, tiempo_transcurrido, paste(numGoodCorrelations,"/",numCorrelations, sep="") ,sep="\t"), "\n")
# }, warning = function(w) {
#   # Manejo de advertencias
#   message("Advertencia: ", conditionMessage(w))
#   # Retornar algo si es necesario
# })  