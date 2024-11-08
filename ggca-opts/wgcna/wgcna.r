suppressMessages({
  library("WGCNA")
  library("reshape2")
  library("data.table")
  library("compiler")
  library("future")
  library("future.apply")
})

# Set the maximum size of global variables to prevent issues with large datasets
options(future.globals.maxSize = 1024 * 1024 * 1024 * 2)  # 2 GB in bytes

unnecessary_output <- capture.output({
  enableJIT(3)
})


# Arg 1: method (single-pearson, single-spearman or single-kendall)
# Arg 2: number of threads
# Arg 3: dataset GEM
# Arg 4: dataset GENE

args <- commandArgs(trailingOnly = TRUE)

method = args[[1]]
threads = as.numeric(args[[2]])
dataset1.gem.path = args[[3]]
dataset2.gene.path = args[[4]]

if(args[[1]] == "single-pearson"){
  method = "pearson"
} else if (args[[1]] == "single-kendalls") {
   method = "kendall"
} else if (args[[1]] == "single-spearman") {
   method = "spearman"
} else {
  cat("args[[1]] should be one of “single-pearson”, “single-kendalls” or “single-spearman”")
}

# I specify that there are parts of code (specified with future_lapply) that run in parallel
plan(multisession, workers = threads) 
# Correlation_threshold or r.minimium value
r.minimium=0.5
# Method of adjusting the p-value. Possible options: "bonferroni", "holm", "hochberg", "hommel", "BH" (or its alias "fdr"), "BY"
metodo_ajuste="fdr"
# Number of final correlations (best N results after applying the Correlation_threshold)
keep_top_n=10

# Utils
readFile <- function(file_path) {
  file <- na.omit(read.table(file_path, header=TRUE, row.names = NULL, sep="\t", check.names=F))
  return (file)
}

SortMatrixByColumnName <- function(x, colsToExclude=0){
	return (x[,union(c(1), order(colnames(x)[2:length(colnames(x))])+1)])	
}

gem.dataset <- readFile(dataset1.gem.path)
gene.dataset <- readFile(dataset2.gene.path)

row.names(gem.dataset)<-gem.dataset[,1]
row.names(gene.dataset)<-gene.dataset[,1]
gem.dataset<-gem.dataset[,2:ncol(gem.dataset)]
gene.dataset<-gene.dataset[,2:ncol(gene.dataset)]

# Enable parallel processing for WCGNA Correlation (only if threads > 1)
if (threads > 1) {
  # Set the number of threads to be used by WGCNA
  unnecessary_output <- capture.output({
    th = enableWGCNAThreads(threads)
  })
} else {
  th = 1
}

# cat(paste("Dataset", "Algorithm", "Optimization", "Threads", "Finished time (ms)", "Combinations evaluated",sep="\t"), "\n")
# transpose matrix before correlation
gem.dataset.transposed <-t(gem.dataset)
gene.dataset.transposed <- t(gene.dataset)

gem.dataset.transposed.numeric <- future_apply(gem.dataset.transposed, 2, as.numeric) 
gene.dataset.transposed.numeric <- future_apply(gene.dataset.transposed, 2, as.numeric) 

ptm <- proc.time()
correlation.start <- proc.time()

# Calculate correlation between x and y using  WCGNA
cor.and.pvalue <- corAndPvalue(gem.dataset.transposed.numeric, gene.dataset.transposed.numeric, method=method, nThreads=th)
# get number of calculated correlations
numCorrelations <- length(cor.and.pvalue$p[!is.na(cor.and.pvalue$p)])

# correlation result into a dataframe
cor.melt<-reshape2::melt(cor.and.pvalue$cor)
colnames(cor.melt) <- c("x","y","correlation")
# Filter rows with a correlation that does not meet the minimum required value
cor.melt <- subset(cor.melt, abs(correlation) > r.minimium)

# get number of correlations that pass the set threshold
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

# Keep the best N correlations in the results
resultado <- result.table[order(-correlation)][1:keep_top_n]

# Elapsed time for calculation of collelation and adjustments:
elapsed_time = (proc.time() - correlation.start)["elapsed"] * 1000
cat(paste(args[[1]], "wgcna_R", threads, elapsed_time, paste(numGoodCorrelations,"/",numCorrelations, sep="") ,sep="\t"), "\n")
