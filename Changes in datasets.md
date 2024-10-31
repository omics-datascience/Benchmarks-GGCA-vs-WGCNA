# Description of Used Datasets

We used real transcriptomic and methylation datasets to perform the correlations with the different algorithms. The [TCGA Breast Cancer (BRCA)](https://xenabrowser.net/datapages/?cohort=TCGA%20Breast%20Cancer%20(BRCA)&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443) data cohort obtained from UCSC XENA was used.
Specifically, a DNA methylation dataset (identifier [TCGA.BRCA.sampleMap/HumanMethylation450](https://xenabrowser.net/datapages/?dataset=TCGA.BRCA.sampleMap%2FHumanMethylation450&host=https%3A%2F%2Ftcga.xenahubs.net&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443)) and the gene expression RNAseq dataset (identifier [TCGA.BRCA.sampleMap/HiSeqV2_PANCAN](https://xenabrowser.net/datapages/?dataset=TCGA.BRCA.sampleMap%2FHiSeqV2_PANCAN&host=https%3A%2F%2Ftcga.xenahubs.net&removeHub=https%3A%2F%2Fxena.treehouse.gi.ucsc.edu%3A443)) were used.  
These data sets were reduced in size and processed as explained below in the next section.  

## Changes in datasets

The entire procedure performed for these benchmarks is listed below:  

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
