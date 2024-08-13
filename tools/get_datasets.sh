#!/bin/bash

# UCSC Xena datasets used
# Cohort: TCGA Breast Cancer (BRCA)
# Cohort URL: https://xenabrowser.net/datapages/?cohort=TCGA%20Breast%20Cancer%20(BRCA)&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443
# Datasets:
# Gene Expression Modulators (GEM) data: TCGA.BRCA.sampleMap/HumanMethylation450
# Gene Expression Data (GENES): TCGA.BRCA.sampleMap/HiSeqV2_PANCAN


URL_GEM="https://tcga-xena-hub.s3.us-east-1.amazonaws.com/download/TCGA.BRCA.sampleMap%2FHumanMethylation450.gz"
URL_GENES="https://tcga-xena-hub.s3.us-east-1.amazonaws.com/download/TCGA.BRCA.sampleMap%2FHiSeqV2_PANCAN.gz" 

OUTPUT_GEM="TCGA.BRCA.sampleMap_HumanMethylation450.gz"
OUTPUT_GENE="TCGA.BRCA.sampleMap_HiSeqV2_PANCAN.gz"

DATASETS_SIZES=(1 10 100 500 1000 1500 2000)

echo "Downloading datasets..."
curl -o "../datasets/$OUTPUT_GEM" "$URL_GEM"
curl -o "../datasets/$OUTPUT_GENE" "$URL_GENES"

echo -n "Unzipping files..."
gunzip -c "../datasets/$OUTPUT_GEM" > ../datasets/TCGA_BRCA_sampleMap_HumanMethylation450
gunzip -c "../datasets/$OUTPUT_GENE" > ../datasets/TCGA_BRCA_sampleMap_HiSeqV2_PANCAN
rm "../datasets/$OUTPUT_GEM"
rm "../datasets/$OUTPUT_GENE"
echo "ok"

echo "processing raw datasets..."
python3 dataset_processing.py --dataset_1 ../datasets/TCGA_BRCA_sampleMap_HumanMethylation450 --dataset_2 ../datasets/TCGA_BRCA_sampleMap_HiSeqV2_PANCAN
rm "../datasets/TCGA_BRCA_sampleMap_HumanMethylation450"
rm "../datasets/TCGA_BRCA_sampleMap_HiSeqV2_PANCAN"

echo -n "Assembling datasets of different sizes..."
for DATASET_SIZE in "${DATASETS_SIZES[@]}"
do
    python3 data_subset_by_size_generator.py --input_file ../datasets/TCGA_BRCA_sampleMap_HumanMethylation450_processed.tsv --size_mb $DATASET_SIZE
done
python3 data_subset_by_size_generator.py --input_file ../datasets/TCGA_BRCA_sampleMap_HiSeqV2_PANCAN_processed.tsv --size_mb 5
echo "ok"

echo "You can find the processed files in the "datasets" folder."
echo "The details of the changes made to the datasets are available in the readme.md file."