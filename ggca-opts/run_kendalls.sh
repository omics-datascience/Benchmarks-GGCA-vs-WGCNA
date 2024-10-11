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
		/usr/bin/time -f "$DS\t$PROGRAM_NAME\t$VERSION\t$THREADS\t%M\t%K\t%D\t%P" \
		-o "../../results/$result_for_memory" -a \
		./target/release/examples/$PROGRAM_NAME $THREADS "../../datasets/$DATASET_1" "../../datasets/$DATASET_2"
	done

	cd ../
done

# Run WGCNA
for ((i=1; i<=$REPETITIONS; i++))
do
	/usr/bin/time -f "$DS\t$PROGRAM_NAME\tWGCNA\t$THREADS\t%M\t%K\t%D\t%P" \
	-o "../results/$result_for_memory" -a \
    Rscript --vanilla --quiet wgcna/wgcna.r $PROGRAM_NAME $THREADS "../datasets/$DATASET_1" "../datasets/$DATASET_2"
done