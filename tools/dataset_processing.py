import gc
import dask.dataframe as dd
import argparse
import os

# Dictionary for counting repetitions
repetitions = {}

def save_in_parts(dataset, output_file, sep='\t'):
    """
    Save a Dask DataFrame to a CSV file in parts to better manage memory.
    """
    nparts = dataset.npartitions
    for i in range(nparts):
        part = dataset.get_partition(i).compute()
        if i == 0:
            part.to_csv(output_file, sep=sep, mode='w', index=False)
        else:
            part.to_csv(output_file, sep=sep, mode='a', index=False, header=False)
        del part
        gc.collect()

def add_suffix(value):
    """
    Function to add incremental suffixes
    """
    global repetitions
    if value in repetitions:
        repetitions[value] += 1
        return f"{value}_{repetitions[value]}"
    else:
        repetitions[value] = 0
        return value

def truncate_values(dataset):
    """
    Truncate decimal values ​​in dataframe columns (except the first) to 4 decimal places
    """
    dataset = dataset.copy()
    for col in dataset.columns:
        if dataset[col].dtype in ['float64', 'float32']:
            dataset[col] = dataset[col].round(4)
    return dataset

def sample_intersection(dataset_1_file, dataset_2_file):
    """
    It intersects the samples of the datasets so that they have the same number of
    samples (columns), always maintaining the first column of each dataset.
    """
    # Load the datasets with Dask
    dataset_1 = dd.read_csv(dataset_1_file, sep='\t', blocksize='64MB')
    dataset_2 = dd.read_csv(dataset_2_file, sep='\t', blocksize='64MB')

    # Keep the first column of each dataset
    first_column_1 = dataset_1.columns[0]
    first_column_2 = dataset_2.columns[0]

    # Get the common samples from the second column onwards
    common_samples = list(set(dataset_1.columns[1:]).intersection(set(dataset_2.columns[1:])))

    # Ensure that the first column of each dataset is always maintained
    common_samples_1 = [first_column_1] + common_samples
    common_samples_2 = [first_column_2] + common_samples

    # Filter the datasets to contain only the common samples
    dataset_1_filtered = dataset_1[common_samples_1]
    del dataset_1
    gc.collect() 
    dataset_2_filtered = dataset_2[common_samples_2]
    del dataset_2
    gc.collect() 

    print(f"Intersection completed. {len(common_samples)} common samples found.")
    return dataset_1_filtered, dataset_2_filtered, common_samples

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Script to process datasets.")
    parser.add_argument('--dataset_1', help="TSV file of the first dataset", required=True)
    parser.add_argument('--dataset_2', help="TSV file of the second dataset", required=True)

    args = parser.parse_args()
    
    # Intersection of columns
    dataset_1, dataset_2, common_samples = sample_intersection(args.dataset_1, args.dataset_2)
    
    # Generate output file names
    dataset_1_output_name = os.path.splitext(args.dataset_1)[0] + "_processed.tsv"
    dataset_2_output_name = os.path.splitext(args.dataset_2)[0] + "_processed.tsv"
    
    print("Deleting rows with missing values...")
    dataset_1 = dataset_1.dropna()
    dataset_2 = dataset_2.dropna()
    
    print("Adding suffixes to first column...")
    first_column = dataset_1.columns.tolist()[0]
    dataset_1[first_column] = dataset_1[first_column].map_partitions(lambda col: col.apply(add_suffix), meta=(first_column, 'object'))
    first_column = dataset_2.columns.tolist()[0]
    dataset_2[first_column] = dataset_2[first_column].map_partitions(lambda col: col.apply(add_suffix), meta=(first_column, 'object'))

    print("Truncating values ​​to 4 decimal places...")
    dataset_1 = dataset_1.map_partitions(truncate_values)
    dataset_2 = dataset_2.map_partitions(truncate_values)
    
    print("Saving processed dataset 1...")
    save_in_parts(dataset_1, dataset_1_output_name, sep='\t')
    del dataset_1
    gc.collect() 
    print("Saving processed dataset 2...")
    save_in_parts(dataset_2, dataset_2_output_name, sep='\t')

    print("Finished! Processed datasets saved in:")
    print(f"{dataset_1_output_name}")
    print(f"{dataset_2_output_name}")