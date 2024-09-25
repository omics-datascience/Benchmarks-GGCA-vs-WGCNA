# Benchmarks GGCA vs WGCNA

- [Benchmarks GGCA vs WGCNA](#benchmarks-ggca-vs-wgcna)
  - [Introduction](#introduction)
  - [Requirements](#requirements)
    - [Programming languages](#programming-languages)
    - [Libraries](#libraries)
      - [GNU Scientific Library](#gnu-scientific-library)
      - [R libraries](#r-libraries)
      - [Python packages](#python-packages)
  - [Transcriptomic dataset](#transcriptomic-dataset)
    - [Downloading and processing the datasets](#downloading-and-processing-the-datasets)
      - [Changes in datasets](#changes-in-datasets)
  - [Description of response speed tests](#description-of-response-speed-tests)
    - [Test 1: Using datasets of different sizes](#test-1-using-datasets-of-different-sizes)
    - [Test 2: Using datasets with different number of combinations](#test-2-using-datasets-with-different-number-of-combinations)
  - [Configure benchmarks](#configure-benchmarks)
  - [Run Benchmarck](#run-benchmarck)
  - [Results](#results)
  - [Analysis of Results](#analysis-of-results)
  - [Time and memory measurements](#time-and-memory-measurements)

## Introduction

This benchmark measures the performance of 2 data correlation algorithms using transcriptomic data.
The algorithms tested are:

1. GGCA
2. WGCNA

The tests consist of measuring the performance of the algorithms by measuring their calculation speed and memory usage.

These measurements are obtained in two different ways:

1. Using datasets of different sizes.
2. Using datasets with different numbers of combinations evaluated by the algorithms.

The datasets used and how to get them are described below. This is followed by a section detailing the tests performed.

## Requirements

### Programming languages

- R version 4.4.1
- Python version 3.10
- Rustc version 1.81

### Libraries

#### GNU Scientific Library

To run the benchmarks, you need to have The GNU Scientific Library (GSL) installed. To install, go to the requirements/gsl-latest/gsl-2.7.1 folder and see the INSTALL file for more detailed instructions. For more details see the README file inside the same folder.

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

## Transcriptomic dataset

We used real transcriptomic datasets to perform the correlations with the different algorithms. The [TCGA Breast Cancer (BRCA)](https://xenabrowser.net/datapages/?cohort=TCGA%20Breast%20Cancer%20(BRCA)&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443) data cohort obtained from UCSC XENA was used.
Specifically, a DNA methylation dataset (identifier [TCGA.BRCA.sampleMap/HumanMethylation450](https://xenabrowser.net/datapages/?dataset=TCGA.BRCA.sampleMap%2FHumanMethylation450&host=https%3A%2F%2Ftcga.xenahubs.net&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443)) and the gene expression RNAseq dataset (identifier [TCGA.BRCA.sampleMap/HiSeqV2_PANCAN](https://xenabrowser.net/datapages/?dataset=TCGA.BRCA.sampleMap%2FHiSeqV2_PANCAN&host=https%3A%2F%2Ftcga.xenahubs.net&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443)) were used.

### Downloading and processing the datasets

To download and process the datasets, install the necessary python requirements (python 3.10 is required):  

Then use the following bash script to download, unzip and process the datasets:

``` bash
cd tools
./get_datasets.sh
```

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

## Description of response speed tests

The tests consist of running the correlations using WGCNA and different GGCA optimizations.
Both algorithms were configured as follows:

- Method for adjusting p values: Benjamini and Hochberg.
- Correlation threshold of 0.5
- Keep only the 10 best results.

The algorithms for performing the correlations were run with 3 different methods. Pearson, Kendalls and Spearman methods were used.

The resulting times were measured in milliseconds and include the time taken to perform the correlations, to adjust the p values, to apply the correlation threshold and to retain the 10 best results.

### Test 1: Using datasets of different sizes

For these tests, subsets of the downloaded USCS XENA datasets of different sizes are used. The datasets are created with the script mentioned in section [Downloading and processing the datasets](#downloading-and-processing-the-datasets).  

A fixed 5 MB dataset with transcription data is used and compared with datasets of different sizes with gene expression modulation data (methylation data). The sizes of these datasets are 1, 10, 100, 500, 1000, 1500 and 2000 MB.

### Test 2: Using datasets with different number of combinations

## Configure benchmarks

Edit with numeric values the following variables in the *run_all_by_size.sh* file:

- REPETITIONS: Number of times the same test is repeated to obtain response times. Default: 3.
- THREADS: List of values ​​that represent how many processing threads will be used in each test. Default: 8.
- DATASETS: *This variable does not have to be modified*. List that defines the data sets sizes (MB) that will be used in the tests. Datasets of sizes 1, 10, 100, 500, 1000, 1500 and 2000 MB are always used.

## Run Benchmarck

Use './run_all_by_size.sh' to run benchmarks

## Results

Once the benchmarks have been run, the following TSV files will be generated:

- results_benchmark_by_size.tsv
- results_benchmark_by_number_of_combinations.tsv

These files will contain the times in milliseconds that each algorithm took to perform the tests. The results are in turn classified by the method used, the number of threads, the dataset used and the number of combinations evaluated.

## Analysis of Results

TODO: Describe the analysis that will be performed in Excel, Python, R or wherever it is done

## Time and memory measurements

/usr/bin/time was used to measure memory. The following memory measurements were obtained:

- Max resident memory: includes the maximum resident memory used by the main process and all its threads.
- Total memory: includes the total memory used, which includes both the memory of the main process and that of all threads.
- Unshared memory: refers to the memory that is not shared with other processes, that is, the memory that is exclusive to your process.
