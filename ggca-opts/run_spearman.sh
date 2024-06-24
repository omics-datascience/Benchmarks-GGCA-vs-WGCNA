#!/bin/bash
# Arg 1: number of repetitions
# Arg 2: dataset size in MB (100, 500 or 1500)
# Arg 3: number of threads

# Set env variables
PROGRAM_NAME=single-spearman

 # Run tests
for VERSION in base opt-1 opt-2 opt-3 opt-4
do
	# echo "$VERSION, $PROGRAM_NAME: Testing T=$3"
	cd $VERSION
	cargo build --example $PROGRAM_NAME --no-default-features --release -q

	for ((i=1; i<=$1; i++))
	do
		./target/release/examples/$PROGRAM_NAME $3 "../../datasets/gem-$2mb.csv"
		#cargo run --example $PROGRAM_NAME --no-default-features --release -q $4 "../gem-$3mb.csv"
	done

	cd ../
done

# Run WGCNA
for ((i=1; i<=$1; i++))
do
    Rscript --vanilla wgcna/wgcna.r $2 $3 $PROGRAM_NAME
done