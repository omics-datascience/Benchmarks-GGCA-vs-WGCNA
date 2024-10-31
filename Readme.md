# Benchmarks GGCA vs WGCNA

- [Benchmarks GGCA vs WGCNA](#benchmarks-ggca-vs-wgcna)
  - [Introduction](#introduction)
  - [Requirements](#requirements)
  - [Build Docker Image](#build-docker-image)
  - [Configure benchmarks](#configure-benchmarks)
    - [Downloading and processing the datasets](#downloading-and-processing-the-datasets)
  - [Run Benchmarck](#run-benchmarck)
  - [Description of tests](#description-of-tests)
    - [Test 1: Using datasets of different sizes](#test-1-using-datasets-of-different-sizes)
    - [Test 2: Using datasets with different number of combinations](#test-2-using-datasets-with-different-number-of-combinations)
    - [Time and memory measurements](#time-and-memory-measurements)
  - [Results](#results)
  - [Analysis of Results](#analysis-of-results)

## Introduction

This benchmark measures the performance of 2 data correlation algorithms using transcriptomic data.
The algorithms tested are:

1. [Gene GEM Correlation Analysis (GGCA)](https://docs.rs/ggca/latest/ggca/#)
2. [Weighted Correlation Network Analysis (WGCNA)](https://cran.r-project.org/web/packages/WGCNA/index.html)

The tests consist of measuring the performance of the algorithms by measuring their calculation speed and memory usage.

These measurements are obtained in two different ways:

1. Using datasets of different sizes.
2. Using datasets with different numbers of combinations evaluated by the algorithms.

The data sets used and how to get them are described below in this documentation.

## Requirements

To run the project, the following programming language versions are required: R 4.4.1 and Rust 1.81.0. Additionally, some libraries are required to run the benchmarks. These include the GNU Scientific Library (GSL), GGCA (for Rust) and WGCNA (for R). All of these and the other dependencies will be installed automatically when building the Docker image.

## Build Docker Image

Use `docker build -t ggca-vs-wgcna:latest .` to build de docker image.  

## Configure benchmarks

Create 2 local folders called **datasets** and **results**. For example:  

``` bash
  mkdir ~/datasets
  mkdir ~/results
```

### Downloading and processing the datasets

We used real transcriptomic and methylation datasets to perform the correlations with the different algorithms. The datasets used and the processing performed are detailed in the document [Changes in datasets](Changes%20in%20datasets.md).  

Download and manually unzip [this file](https://drive.google.com/file/d/1aKqm2aKNn4ndHZl5nfk6fm2O7eTulipF/view?usp=sharing). Place all downloaded files inside the **datasets** folder, created previously.

**Alternative**: You can use the following command to download and process the original datasets.  
Replace *<datasets_folder>* with the previously created folder named **datasets** before using the command

``` bash
  docker container run --rm -v <datasets_folder>:datasets ggca-vs-wgcna:latest download-datasets
```

This process will take several minutes, depending on your connection speed and hardware. The processed datasets will be stored inside the 'datasets' folder.  

## Run Benchmarck

Use the following commands to run the benchmarks. Remember to change <datasets_folder> and <results_folder> in the commands to the respective **datasets** and **results** folders created previously.  

Use `docker container run --rm -v <datasets_folder>:datasets -v <results_folder>:results ggca-vs-wgcna:latest benchmark-by-size` to run benchmarks using different sizes on the datasets.

Use `docker container run --rm -v <datasets_folder>:datasets -v <results_folder>:results ggca-vs-wgcna:latest benchmark-by-combinations` to run benchmarks using different numbers of combinations on the datasets.

IMPORTANT: These tests are going to take a long time!

## Description of tests

The tests consist of running the correlations using WGCNA and different GGCA optimizations. For each test, the time in milliseconds and memory usage are measured.  

Both algorithms were configured as follows:

- Method for adjusting p values: Benjamini and Hochberg.
- Correlation threshold of 0.5
- Keep only the 10 best results.

The algorithms for performing the correlations were run with 3 different methods. Pearson, Kendalls and Spearman methods were used.

The resulting times were measured in milliseconds and include the time taken to perform the correlations, to adjust the p values, to apply the correlation threshold and to retain the 10 best results.

The tests are run with 3 repetitions and using different numbers of processing threads. 4, 6 and 8 threads are used.

### Test 1: Using datasets of different sizes

For these tests, subsets of the downloaded USCS XENA datasets of different sizes are used. The datasets are created with the command mentioned in section [Downloading and processing the datasets](#downloading-and-processing-the-datasets).  

A fixed 5 MB dataset with transcription data is used and compared with datasets of different sizes with gene expression modulation data (methylation data). The sizes of these datasets are 1, 10, 100, 500, 1000, 1500 and 2000 MB.

### Test 2: Using datasets with different number of combinations

For these tests, subsets of the downloaded USCS XENA datasets are used, adjusted in such a way as to obtain different numbers of combinations to be evaluated. The datasets are created with the command mentioned in the section [Downloading and processing the datasets](#downloading-and-processing-the-datasets).

A fixed dataset of 10 records with transcription data is used and compared with datasets of different numbers of records with gene expression modulation data (methylation data). The number of records in these different datasets are 1, 10, 100, 1000, 10000 and 100000 records, such that the algorithms will finally evaluate the following combinations in each test: 10, 100, 1000, 10000, 100000 and 1000000 combinations.

**NOTE:** If for some reason you would like to change your test setup so that you are testing with fewer combinations or sizes, fewer repetitions, or fewer processing threads, you must edit the REPETITIONS, THREADS, DATASETS_SIZES, and DATASETS_COMBINATIONS variables. These are located at the top of the *run_all_by_size.sh* and *run_all_by_number_of_combinations.sh* files. Then you will need to build the Docker image again.  

### Time and memory measurements

*/usr/bin/time* was used to measure memory. The following memory measurements were obtained:

- Max resident memory: includes the maximum resident memory used by the main process and all its threads.
- Total memory: includes the total memory used, which includes both the memory of the main process and that of all threads.
- Unshared memory: refers to the memory that is not shared with other processes, that is, the memory that is exclusive to your process.

To obtain the test execution times we use:  

- For WGCNA: The R function called '*proc.time()*'.
- For GGCA: The '*Instant::now()*' function from the Rust library called 'std::time::Instant'.

## Results

Two TSV files will be generated with the results for each of the tests (by size and by number of combinations), one with the memory and CPU percentage measurements and another with the time measurements.
Once the two tests have been run, we will have the following files inside the **results** folder:  

- "time_results_benchmark_by_combinations_\<date\>.tsv"
- "memory_results_benchmark_by_combinations_\<date\>.tsv"
- "time_results_benchmark_by_size_\<date\>.tsv"
- "memory_results_benchmark_by_size_\<date\>.tsv"

Where \<date\> is the date on which the tests were run

These files will contain the times in milliseconds that each algorithm took to perform the tests and the memory usage in KB. The results are in turn classified by the method used, the number of threads, the dataset used and the number of combinations found/evaluated.

## Analysis of Results

TODO: Describe the analysis that will be performed in Excel, Python, R or wherever it is done
