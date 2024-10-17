# Benchmarks GGCA vs WGCNA

- [Benchmarks GGCA vs WGCNA](#benchmarks-ggca-vs-wgcna)
  - [Introduction](#introduction)
  - [Requirements](#requirements)
    - [Programming languages](#programming-languages)
    - [Libraries](#libraries)
      - [GNU Scientific Library](#gnu-scientific-library)
      - [R libraries](#r-libraries)
      - [Python packages](#python-packages)
  - [Datasets](#datasets)
    - [Downloading and processing the datasets](#downloading-and-processing-the-datasets)
      - [Changes in datasets](#changes-in-datasets)
  - [Description of tests](#description-of-tests)
    - [Test 1: Using datasets of different sizes](#test-1-using-datasets-of-different-sizes)
    - [Test 2: Using datasets with different number of combinations](#test-2-using-datasets-with-different-number-of-combinations)
      - [Time and memory measurements](#time-and-memory-measurements)
  - [Configure benchmarks](#configure-benchmarks)
  - [Run Benchmarck](#run-benchmarck)
  - [Results](#results)
  - [Analysis of Results](#analysis-of-results)

## Introduction

This benchmark measures the performance of 2 data correlation algorithms using transcriptomic data.
The algorithms tested are:

1. GGCA
2. WGCNA

The tests consist of measuring the performance of the algorithms by measuring their calculation speed and memory usage.

These measurements are obtained in two different ways:

1. Using datasets of different sizes.
2. Using datasets with different numbers of combinations evaluated by the algorithms.

The data sets used and how to get them are described below in this documentation.

## Requirements

### Programming languages

- R version 4.4.1 (2024-06-14)
- Python 3.10.12
- Rust 1.81.0

### Libraries

#### GNU Scientific Library

To run the benchmarks, you need to have The GNU Scientific Library (GSL) installed. To install, go to the [requirements/gsl-latest/gsl-2.7.1](requirements/gsl-latest/gsl-2.7.1) folder and see the INSTALL file for instructions. For more details see the README file inside the same folder.

#### R libraries

To install the R libraries, use the following bash script:

``` bash
cd requirements
bash requirements_script.sh
```

NOTE: If you have any permissions problems with the installation of the R libraries, use sudo before the previous command.

#### Python packages

To install Python packages, use the following script:

``` bash
cd requirements
pip3 install -r requirements_python.txt
```

## Datasets

We used real transcriptomic and methylation datasets to perform the correlations with the different algorithms. The [TCGA Breast Cancer (BRCA)](https://xenabrowser.net/datapages/?cohort=TCGA%20Breast%20Cancer%20(BRCA)&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443) data cohort obtained from UCSC XENA was used.
Specifically, a DNA methylation dataset (identifier [TCGA.BRCA.sampleMap/HumanMethylation450](https://xenabrowser.net/datapages/?dataset=TCGA.BRCA.sampleMap%2FHumanMethylation450&host=https%3A%2F%2Ftcga.xenahubs.net&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443)) and the gene expression RNAseq dataset (identifier [TCGA.BRCA.sampleMap/HiSeqV2_PANCAN](https://xenabrowser.net/datapages/?dataset=TCGA.BRCA.sampleMap%2FHiSeqV2_PANCAN&host=https%3A%2F%2Ftcga.xenahubs.net&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443)) were used.  
These datasets were reduced in size and processed as explained in the following section.  

### Downloading and processing the datasets

To download and process the datasets use the following bash script to download, unzip and process the datasets:

``` bash
cd tools
./get_datasets.sh
```

This process will take several minutes, depending on your connection speed and hardware. The processed datasets will be stored inside the 'datasets' folder.  

**Alternative**: If you do not want to download and process the datasets, you can download the dataset folder from [here](https://drive.google.com/file/d/1aKqm2aKNn4ndHZl5nfk6fm2O7eTulipF/view?usp=sharing). You will then need to unzip it into the project's root folder.

#### Changes in datasets

The above script not only downloads the datasets in TSV format, but also makes some changes to them and assembles the datasets of different sizes to be used in the benchmark tests. All the processing performed by the script is listed below:

1. **Sample Intersection:**
Identifies the common columns (samples) between the two datasets downloaded from UCSC XENA, ensuring that the first column of each file is maintained (corresponding to the gene or modulator identifier). Then, it filters the datasets so that they only contain the common columns in both final datasets.
2. **Removal of Rows with Missing Values:**
Removes rows in which there are missing values ​​in any of the columns.
3. **Removal of Rows with Identical Values:**
Removes rows where all column values ​​are identical, since they do not contribute variability (and therefore have no standard deviation).
4. **Adding Suffixes to the First Column:**
Adds incremental suffixes to the values ​​in the first column to ensure that each value is unique. Many times in this type of datasets we can find two identical genes since they can refer to different transcripts of the same gene. This is often a problem when performing correlation analysis since genes or expression modulators cannot be differentiated.
5. **Truncation of Decimal Values:**
Rounds decimal values ​​in all columns (except the first) to 4 decimal places. This is so that both datasets have the same precision.
6. **Saving Processed Datasets:**
Saves processed datasets in TSV files. Processing is done using the Python library called Dask and is done in parts to manage memory efficiently.
7. **Building and Saving Datasets with the sizes to be used in the tests**
The script also automatically builds files of different sizes. These files will be used in the benchmark.
8. **Creating and storing data sets with different numbers of combinations to be evaluated in the tests**
The script finally automatically creates files with different numbers of combinations to be compared and evaluated by the tested algorithms.

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

For these tests, subsets of the downloaded USCS XENA datasets of different sizes are used. The datasets are created with the script mentioned in section [Downloading and processing the datasets](#downloading-and-processing-the-datasets).  

A fixed 5 MB dataset with transcription data is used and compared with datasets of different sizes with gene expression modulation data (methylation data). The sizes of these datasets are 1, 10, 100, 500, 1000, 1500 and 2000 MB.

### Test 2: Using datasets with different number of combinations

For these tests, subsets of the downloaded USCS XENA datasets are used, adjusted in such a way as to obtain different numbers of combinations to be evaluated. The datasets are created with the script mentioned in the section [Downloading and processing the datasets](#downloading-and-processing-the-datasets).

A fixed dataset of 10 records with transcription data is used and compared with datasets of different numbers of records with gene expression modulation data (methylation data). The number of records in these different datasets are 1, 10, 100, 1000, 10000 and 100000 records, such that the algorithms will finally evaluate the following combinations in each test: 10, 100, 1000, 10000, 100000 and 1000000 combinations.

#### Time and memory measurements

*/usr/bin/time* was used to measure memory. The following memory measurements were obtained:

- Max resident memory: includes the maximum resident memory used by the main process and all its threads.
- Total memory: includes the total memory used, which includes both the memory of the main process and that of all threads.
- Unshared memory: refers to the memory that is not shared with other processes, that is, the memory that is exclusive to your process.

To obtain the test execution times we use:  

- For WGCNA: The R function called '*proc.time()*'.
- For GGCA: The '*Instant::now()*' function from the Rust library called 'std::time::Instant'.

## Configure benchmarks

You just need to edit the RUSTFLAGS environment variable in the *run_all_by_size.sh* and *run_all_by_number_of_combinations.sh* files. The value to be assigned must be the path where the python libraries "config-3.10-x86_64-linux-gnu" are located.
By default, the script has the variable set as:  
`export RUSTFLAGS="-L /usr/lib/python3.10/config-3.10-x86_64-linux-gnu -lpython3.10"`  
If the library is not in that directory on your computer, set the variable to the correct directory.  

If for some reason you would like to change your test setup so that you are testing with fewer combinations or sizes, fewer repetitions, or fewer processing threads, you must edit the REPETITIONS, THREADS, DATASETS_SIZES, and DATASETS_COMBINATIONS variables. These are located at the top of the *run_all_by_size.sh* and *run_all_by_number_of_combinations.sh* files.  

## Run Benchmarck

Use `./run_all_by_size.sh` to run benchmarks using different sizes on the datasets.

Use `./run_all_by_number_of_combinations.sh` to run benchmarks using different numbers of combinations on the datasets.

IMPORTANT: These tests are going to take a long time!

## Results

Two TSV files will be generated with the results for each of the tests (by size and by number of combinations), one with the memory and CPU percentage measurements and another with the time measurements.
Once the two tests have been run, we will have the following files inside the [results](results) folder:  

- "time_results_benchmark_by_combinations_\<date\>.tsv"
- "memory_results_benchmark_by_combinations_\<date\>.tsv"
- "time_results_benchmark_by_size_\<date\>.tsv"
- "memory_results_benchmark_by_size_\<date\>.tsv"

Where \<date\> is the date on which the tests were run

These files will contain the times in milliseconds that each algorithm took to perform the tests and the memory usage in KB. The results are in turn classified by the method used, the number of threads, the dataset used and the number of combinations found/evaluated.

## Analysis of Results

TODO: Describe the analysis that will be performed in Excel, Python, R or wherever it is done


