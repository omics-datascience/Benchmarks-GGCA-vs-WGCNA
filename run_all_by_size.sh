#!/bin/bash
REPETITIONS=3
THREADS=(8)
# DATASETS_SIZES=(1 10 100 500 1000 1500 2000 2500)
DATASETS_SIZES=(1 10)

FIXED_DATASET="HiSeqV2_PANCAN_procesado-5mb.tsv"

for THREAD in "${THREADS[@]}"
do
    for DATASET_SIZE in "${DATASETS_SIZES[@]}"
    do
        DATASET="HumanMethylation450_procesado-${DATASET_SIZE}mb.tsv"
        cd ggca-opts
        echo "#Dataset" $DATASET_SIZE "MB - " $THREAD Threads
        echo -e "Algorithm\tOptimization\tThreads\tFinished time (ms)\tCombinations evaluated" >"../$DATASET_SIZE-$THREAD.tsv"
        echo "Corriendo Pearson..."
        bash run_pearson.sh $REPETITIONS $THREAD $DATASET $FIXED_DATASET >>"../$DATASET_SIZE-$THREAD.tsv"
        echo "Corriendo Kendalls..."
        bash run_kendalls.sh $REPETITIONS $THREAD $DATASET $FIXED_DATASET >>"../$DATASET_SIZE-$THREAD.tsv"
        echo "Corriendo Spearman..."
        bash run_spearman.sh $REPETITIONS $THREAD $DATASET $FIXED_DATASET >>"../$DATASET_SIZE-$THREAD.tsv"
        cd ..
    done
done


# ARMO RESULTADOS EN UN UNICO TSV ORDENADO
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