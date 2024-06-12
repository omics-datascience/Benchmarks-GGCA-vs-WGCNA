#!/bin/bash
REPETITIONS=3

for THREAD in 6 8
do
    for DATASET in 5 20
    do
        cd ggca-opts
        echo "#Dataset" $DATASET "MB - " $THREAD Threads
        echo -e "Algorithm\tOptimization\tThreads\tFinished time (ms)\tCombinations evaluated" >"../$DATASET-$THREAD.tsv"
        echo "Corriendo Pearson..."
        bash run_pearson.sh $REPETITIONS $DATASET $THREAD >>"../$DATASET-$THREAD.tsv"
        Rscript wgcna/wgcna.r $REPETITIONS $DATASET $THREAD pearson >>"../$DATASET-$THREAD.tsv"
        echo "Corriendo Kendalls..."
        bash run_kendalls.sh $REPETITIONS $DATASET $THREAD >>"../$DATASET-$THREAD.tsv"
        Rscript wgcna/wgcna.r $REPETITIONS $DATASET $THREAD kendall >>"../$DATASET-$THREAD.tsv"
        echo "Corriendo Spearman..."
        bash run_spearman.sh $REPETITIONS $DATASET $THREAD >>"../$DATASET-$THREAD.tsv"
        Rscript wgcna/wgcna.r $REPETITIONS $DATASET $THREAD spearman >>"../$DATASET-$THREAD.tsv"
        cd ..
    done
done


# ARMO RESULTADOS EN UN UNICO TSV ORDENADO
output="resultados.tsv"
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
        echo -e "${primer_string}\t${line}" >> "$output"
      fi
    fi
  done < "$archivo"
  rm -f $archivo
done

# GENERO LOS GRAFICOS
python3 graficar_resultados.py $output