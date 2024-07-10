import pandas as pd
import os
import argparse

parser = argparse.ArgumentParser(description='Procesar dataset para generar data subsets de tamaños especificados.')
parser.add_argument('--input_file', type=str, required=True, help='El nombre del dataset de entrada')
parser.add_argument('--output_file', type=str, required=True, help='El nombre del data subset de salida')
parser.add_argument('--size_mb', type=int, required=True, help='El tamaño en MB del data subset de salida')
parser.add_argument('--sample_size', type=int, required=False, default=50, help='El tamaño en MB del data subset de salida')


args = parser.parse_args()

df = pd.read_csv(args.input_file, sep='\t')

# Armo una muestra para calcular el tamaño aproximado de los registros dentro del dataset
sample = df.head(args.sample_size)
sample.to_csv('/tmp/sample.tsv', sep='\t', index=False)

# Tamaño del archivo de muestra en bytes
sample_file_size = os.path.getsize('/tmp/sample.tsv')
os.remove('/tmp/sample.tsv')

# Tamaño promedio por fila
avg_row_size = sample_file_size / args.sample_size

# convierto MB a bytes
size_bytes = args.size_mb * 1024 * 1024

# calculo numero de filas necesarias para el subset
rows_number = int(size_bytes / avg_row_size)

# Seleccionar el subconjunto del DataFrame (obtengo las rows_number primeras filas)
subset_df = df.head(rows_number)

# Guardar el subset
subset_df.to_csv(args.output_file, sep='\t', index=False)
