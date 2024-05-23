#!/bin/bash
REPETITIONS=10

for THREAD in 2 4 6
do
    for DATASET in 100 500 1500
    do
        cd ggca-opts
        echo $THREAD $DATASET
        bash run_pearson.sh $REPETITIONS $DATASET $THREAD
        bash run_kendalls.sh $REPETITIONS $DATASET $THREAD
        bash run_spearman.sh $REPETITIONS $DATASET $THREAD
        cd ../
    done
done