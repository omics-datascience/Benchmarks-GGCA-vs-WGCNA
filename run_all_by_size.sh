#!/bin/bash
# REPETITIONS=3
# THREADS=(8)
# DATASETS_SIZES=(1 10 100 500 1000 1500 2000)

REPETITIONS=1
THREADS=(8)
DATASETS_SIZES=(1)

FIXED_DATASET="TCGA_BRCA_sampleMap_HiSeqV2_PANCAN_clean_processed_5MB.tsv"

for THREAD in "${THREADS[@]}"
do
    for DATASET_SIZE in "${DATASETS_SIZES[@]}"
    do
        DATASET="TCGA_BRCA_sampleMap_HumanMethylation450_clean_processed_${DATASET_SIZE}MB.tsv"
        cd ggca-opts
        echo "#Dataset" $DATASET_SIZE "MB - " $THREAD Threads
        echo -e "Algorithm\tOptimization\tThreads\tFinished time (ms)\tCombinations evaluated" >"../$DATASET_SIZE-$THREAD.tsv"
        echo "Running Pearson..."
        bash run_pearson.sh $REPETITIONS $THREAD $DATASET $FIXED_DATASET >>"../$DATASET_SIZE-$THREAD.tsv"
        echo "Running Kendalls..."
        bash run_kendalls.sh $REPETITIONS $THREAD $DATASET $FIXED_DATASET >>"../$DATASET_SIZE-$THREAD.tsv"
        echo "Running Spearman..."
        bash run_spearman.sh $REPETITIONS $THREAD $DATASET $FIXED_DATASET >>"../$DATASET_SIZE-$THREAD.tsv"
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