#!/bin/bash
# Arg 1: number of repetitions
# Arg 2: dataset size in MB (100, 500 or 1500)

# Run tests
for ((i=1; i<=$1; i++))
do
	cargo run --example single-spearman --no-default-features --release -q "../gem-$2mb.csv"
done
