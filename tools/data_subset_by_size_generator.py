import os
import dask.dataframe as dd
import argparse

parser = argparse.ArgumentParser(description='Process dataset to generate data subsets of specified sizes.')
parser.add_argument('--input_file', type=str, required=True, help='The name of the input dataset')
parser.add_argument('--size_mb', type=int, required=True, help='The size in MB of the output data subset')
args = parser.parse_args()


def create_tsv_of_size_dask(input_file, output_file, size_mb):
    """
    Creates a TSV file of the size specified by the 'size_mb' parameter from a larger file.
    """
    # Create output directory if it does not exist
    output_dir = os.path.dirname(output_file)
    if not os.path.exists(output_dir) and output_dir:
        os.makedirs(output_dir)
    # Read CSV file into a Dask DataFrame
    ddf = dd.read_csv(input_file, assume_missing=True)
    # Calculate the target size in bytes
    size_bytes = (size_mb*0.954) * 1024 * 1024
    # Create an empty output file to start with
    with open(output_file, 'w') as f:
        header_str = ddf.head(0).to_csv(index=False, header=True)
        f.write(header_str)

    current_size = 0
    rows_written = 0
    # Iterate over partitions of Dask DataFrame
    nparts = ddf.npartitions
    for i in range(nparts):
        partition = ddf.get_partition(i).compute()
        for index, row in partition.iterrows():
            row_str = row.to_csv(index=False, header=False)
            row_size = len(row_str.encode('utf-8'))
            current_size += row_size
            rows_written += 1
            # Write the row to the output file
            with open(output_file, 'a') as f:
                f.write(row_str)
            
            if current_size >= size_bytes:
                return  # Exit when target size is reached


output_file = os.path.splitext(args.input_file)[0] + "_"+str(args.size_mb)+"MB.tsv"
create_tsv_of_size_dask(args.input_file, output_file, args.size_mb)
