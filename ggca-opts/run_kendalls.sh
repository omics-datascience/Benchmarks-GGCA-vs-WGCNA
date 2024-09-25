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
for VERSION in base opt-1 opt-2 opt-3 opt-4 opt-5 opt-6 opt-8
do
	cd $VERSION
	if [ "$VERSION" == "opt-8" ]; then
		cargo build --example $PROGRAM_NAME --release -q
	else
		cargo build --example $PROGRAM_NAME --no-default-features --release -q
	fi

	for ((i=1; i<=$REPETITIONS; i++))
	do
		/usr/bin/time -f "Max resident memory (KB)\t%M\nTotal memory (resident + virtual)(KB)\t%K\nUnshared memory (KB)\t%D" \
		-o "../../results/tmp/$PROGRAM_NAME-$REPETITIONS-$THREADS-$VERSION.txt" -a \
		./target/release/examples/$PROGRAM_NAME $THREADS "../../datasets/$DATASET_1" "../../datasets/$DATASET_2"
	done

	cd ../
done

# Run WGCNA
for ((i=1; i<=$REPETITIONS; i++))
do
	/usr/bin/time -f "Max resident memory (KB)\t%M\nTotal memory (resident + virtual)(KB)\t%K\nUnshared memory (KB)\t%D" \
	-o "../results/tmp/$PROGRAM_NAME-$REPETITIONS-$THREADS-WGCNA.txt" -a \
    Rscript --vanilla --quiet wgcna/wgcna.r $PROGRAM_NAME $THREADS "../datasets/$DATASET_1" "../datasets/$DATASET_2"
done