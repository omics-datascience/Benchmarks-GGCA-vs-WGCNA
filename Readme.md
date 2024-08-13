# Benchmarks GGCA vs WGCNA vs PyWGCNA

This benchmark measures the performance of 3 data correlation algorithms using transcriptomic data.
The algorithms tested are:

1. GGCA
2. WGCNA
3. PyWGCNA

The tests consist of measuring the performance of the algorithms by measuring their calculation speed and memory usage.

These measurements are obtained in two different ways:

1. Using datasets of different sizes.
2. Using datasets with different numbers of combinations evaluated by the algorithms.

The datasets used and how to obtain them are described below. This is followed by a section detailing the tests performed.

## Transcriptomic dataset

We used real transcriptomic datasets to perform the correlations with the different algorithms. The [TCGA Breast Cancer (BRCA)](https://xenabrowser.net/datapages/?cohort=TCGA%20Breast%20Cancer%20(BRCA)&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443) data cohort obtained from UCSC XENA was used.
Specifically, a DNA methylation dataset (identifier [TCGA.BRCA.sampleMap/HumanMethylation450](https://xenabrowser.net/datapages/?dataset=TCGA.BRCA.sampleMap%2FHumanMethylation450&host=https%3A%2F%2Ftcga.xenahubs.net&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443)) and the gene expression RNAseq dataset (identifier [TCGA.BRCA.sampleMap/HiSeqV2_PANCAN](https://xenabrowser.net/datapages/?dataset=TCGA.BRCA.sampleMap%2FHiSeqV2_PANCAN&host=https%3A%2F%2Ftcga.xenahubs.net&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443)) were used.

### Downloading and processing the datasets

To download and process the datasets, install the necessary python requirements (python 3.10 is required):  

``` python
pip3 install -r requirements/requirements.txt
```

Then use the following bash script to download, unzip and process the datasets:

``` bash
./get_datasets.sh
```

## Pruebas de velocidad de respuesta

## Mark symbols of repeated genes

Because in the gene expression file "data_mrna_seq_v2_rsem_zscores_ref_all_samples.txt" there are genes with repeated HUGO Symbols, the dataset was processed to add incremental suffixes to those cases. Otherwise, the WGCNA algorithm generated errors due to duplicate row names.  
For this processing, the script *tools/add_suffix_to_duplicates_values.py* was used as follows:

``` bash
    python3 tools/add_suffix_to_duplicates_values.py --input_file datasets/data_mrna_seq_v2_rsem_zscores_ref_all_samples.txt --output_file datasets/data_mrna_seq_v2_rsem_zscores_ref_all_samples_repaired.txt
```

## Subset data

To create subsets of data of different sizes, use the "tools/data_subset_generator.py" script. This tool creates new datasets with a size specified by the "--size_mb" parameter from a dataset passed in the "--input_file" parameter, as shown below:  

``` bash
    python3 tools/data_subset_generator.py --input_file datasets/data_mrna_seq_v2_rsem_zscores_ref_all_samples_repaired.txt --output_file datasets/ejemplo_50mb.tsv --size_mb 50 --sample_size 10
```

The "--output_file" parameter allows you to specify a name for the generated subset.  
The parameter "--sample_size" is optional (the value 50 is assigned if it is not used). This value allows you to take a sample of the first N records within the input_file dataset to estimate the size per record, and in this way determine how many records are necessary to create the new dataset with the size specified in the "--size_mb" parameter.  

## Configure benchmarks

Edit with numeric values the following variables in the *run_all.sh* file:

- REPETITIONS: Number of times the same test is repeated to obtain response times
- THREADS: List of values ​​that represent how many processing threads will be used in each test
- DATASETS: List that defines the data sets that will be used in the tests. You can use the following values: 5, 20, 50, 100, 500 and full

## Run

Use './run_all.sh' to run benchmarks
