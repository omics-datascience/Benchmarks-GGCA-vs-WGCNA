#!/bin/bash

# Checks if exactly one parameter has been passed
if [ "$#" -ne 1 ]; then
    echo "Error: You must provide a parameter."
    echo "Possible parameters: "
    echo "\t- 'benchmark-by-size': to run the benchmark using different sizes of datasets."
    echo "\t- 'benchmark-by-combinations': to run the benchmark evaluating different numbers of combinations."
    echo "\t- 'download-datasets': to download the datasets needed for testing."
    exit 1
fi

# Ejecuta comandos en función del parámetro
case "$1" in
    benchmark-by-size)
        echo "Running benchmark by diferent datsets sizes"
        ./run_all_by_size.sh
        ;;
    benchmark-by-combinations)
        echo "Running benchmark by diferent number of comninations in datasets"
        ./run_all_by_number_of_combinations.sh
        ;;
    download-datasets)
        echo "Download and processing datasets"
        cd tools && ./get_datasets.sh
        ;;
    *)
        echo "Error: Invalid parameter. "
        echo "Possible parameters: "
        echo "\t- 'benchmark-by-size': to run the benchmark using different sizes of datasets."
        echo "\t- 'benchmark-by-combinations': to run the benchmark evaluating different numbers of combinations."
        echo "\t- 'download-datasets': to download the datasets needed for testing."
        exit 1
        ;;
esac