if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(update = TRUE)
BiocManager::install("WGCNA")

if (!require("reshape2", character.only = TRUE)) {
  install.packages("reshape2")
}

if (!require("future", character.only = TRUE)) {
  install.packages("future")
}

if (!require("future.apply", character.only = TRUE)) {
  install.packages("future.apply")
}