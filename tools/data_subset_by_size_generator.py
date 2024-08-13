import os
import dask.dataframe as dd
import argparse

parser = argparse.ArgumentParser(description='Procesar dataset para generar data subsets de tamaños especificados.')
parser.add_argument('--input_file', type=str, required=True, help='El nombre del dataset de entrada')
parser.add_argument('--size_mb', type=int, required=True, help='El tamaño en MB del data subset de salida')
args = parser.parse_args()


def create_tsv_of_size_dask(input_file, output_file, size_mb):
    # Crear el directorio de salida si no existe
    output_dir = os.path.dirname(output_file)
    if not os.path.exists(output_dir) and output_dir:
        os.makedirs(output_dir)
    # Leer el archivo CSV en un DataFrame de Dask
    ddf = dd.read_csv(input_file, assume_missing=True)
    
    # Calcular el tamaño objetivo en bytes
    size_bytes = (size_mb*0.954) * 1024 * 1024

    # Crear un archivo de salida vacío para empezar
    with open(output_file, 'w') as f:
        pass

    current_size = 0
    rows_written = 0
    
    # Iterar sobre particiones del DataFrame de Dask
    nparts = ddf.npartitions
    for i in range(nparts):
        partition = ddf.get_partition(i).compute()
        for index, row in partition.iterrows():
            if i == 0:
                row_str = row.to_csv(index=False, header=True)
            else:
                row_str = row.to_csv(index=False, header=(rows_written == 0))
            row_size = len(row_str.encode('utf-8'))
            current_size += row_size
            rows_written += 1
            
            # Escribir la fila en el archivo de salida
            with open(output_file, 'a') as f:
                f.write(row_str)
            
            if current_size >= size_bytes:
                return  # Salir cuando se alcance el tamaño objetivo


output_file = os.path.splitext(args.input_file)[0] + "_"+str(args.size_mb)+"MB.tsv"
create_tsv_of_size_dask(args.input_file, output_file, args.size_mb)
