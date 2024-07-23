#!/bin/bash
# Arg 1: number of repetitions
# Arg 2: number of threads
# Arg 3: dataset 1
# Arg 4: dataset 2

# Set env variables
PROGRAM_NAME=single-kendalls

REPETITIONS=$1
THREADS=$2
DATASET_1=$3
DATASET_2=$4

 # Run tests
for VERSION in base opt-1 opt-2 opt-3 opt-4 opt-5 opt-6
do
	cd $VERSION
	cargo build --example $PROGRAM_NAME --no-default-features --release -q

	for ((i=1; i<=$REPETITIONS; i++))
	do
		./target/release/examples/$PROGRAM_NAME $THREADS "../../datasets/$DATASET_1" "../../datasets/$DATASET_2"
	done

	cd ../
done

# Run WGCNA
for ((i=1; i<=$REPETITIONS; i++))
do
    Rscript --vanilla wgcna/wgcna.r $PROGRAM_NAME $THREADS "../datasets/$DATASET_1" "../datasets/$DATASET_2"
done