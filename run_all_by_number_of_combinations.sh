#!/bin/bash
set -e

REPETITIONS=3
THREADS=(8)
DATASETS_COMBINATIONS=(10 100 1000 10000 100000 1000000)

export RUSTFLAGS="-L /usr/lib/python3.10/config-3.10-x86_64-linux-gnu -lpython3.10"

FIXED_DATASET="TCGA_BRCA_sampleMap_HiSeqV2_PANCAN_clean_processed_10_rows.tsv"

for THREAD in "${THREADS[@]}"
do
    for DATASETS_COMB in "${DATASETS_COMBINATIONS[@]}"
    do
        DATASET="TCGA_BRCA_sampleMap_HumanMethylation450_clean_processed_${DATASETS_COMB}_combinations.tsv"
        cd ggca-opts
        echo "#Dataset" $DATASETS_COMB "Combinations - " $THREAD Threads
        echo -e "Algorithm\tOptimization\tThreads\tFinished time (ms)\tCombinations evaluated" >"../$DATASETS_COMB-$THREAD.tsv"
        echo "Running Pearson..."
        bash run_pearson.sh $REPETITIONS $THREAD $DATASET $FIXED_DATASET >>"../$DATASETS_COMB-$THREAD.tsv"
        echo "Running Kendalls..."
        bash run_kendalls.sh $REPETITIONS $THREAD $DATASET $FIXED_DATASET >>"../$DATASETS_COMB-$THREAD.tsv"
        echo "Running Spearman..."
        bash run_spearman.sh $REPETITIONS $THREAD $DATASET $FIXED_DATASET >>"../$DATASETS_COMB-$THREAD.tsv"
        cd ..
    done
done


# RESULTS ARE COLLECTED INTO A SINGLE ORDERED TSV
fecha_actual=$(date +%d_%m_%Y)
output="results_benchmark_by_size_$fecha_actual.tsv"
> "$output"

archivos=($(ls | grep -E '[0-9]+-[0-9]+\.tsv$'))

header_written=false

for archivo in "${archivos[@]}"; do
  base_name=$(basename "$archivo" .tsv)
  primer_string=$(echo "$base_name" | cut -d'-' -f1)
  
  while IFS= read -r line; do
    if [[ $header_written == false ]]; then
      echo -e "Dataset\t${line}" >> "$output"
      header_written=true
    else
      if [[ $line != $(head -n 1 "$archivo") ]]; then
        echo -e "${primer_string} MB\t${line}" >> "$output"
      fi
    fi
  done < "$archivo"
  rm -f $archivo
done