# Benchmarks GGCA vs WGCNA

For these tests, the Breast [Invasive Carcinoma dataset (TCGA, Cell 2015)](https://www.cbioportal.org/study/summary?id=br) obtained from the Cbioportal platform was used.  
Specifically, the files "data_methylation_hm27.txt", "data_mrna_seq_v2_rsem_zscores_ref_all_samples.txt" and data subsets of different sizes generated from those two files were used.
  
Because in the gene expression file "data_mrna_seq_v2_rsem_zscores_ref_all_samples.txt" there are genes with repeated HUGO Symbols, the dataset was processed to add incremental suffixes to those cases. Otherwise, the WGCNA algorithm generated errors due to duplicate row names.  
For this processing, the script *tools/add_suffix_to_duplicates_values.py* was used as follows:

``` bash
    python3 tools/add_suffix_to_duplicates_values.py --input_file datasets/data_mrna_seq_v2_rsem_zscores_ref_all_samples.txt --output_file datasets/data_mrna_seq_v2_rsem_zscores_ref_all_samples_repaired.txt
```

## Configuration

Edit with numeric values the following variables in the *run_all.sh* file:

- REPETITIONS: Number of times the same test is repeated to obtain response times
- THREADS: List of values ​​that represent how many processing threads will be used in each test
- DATASETS: List that defines the data sets that will be used in the tests. You can use the following values: 5, 20, 50, 100, 500 and full

## Run

Use './run_all.sh' to run benchmarks
