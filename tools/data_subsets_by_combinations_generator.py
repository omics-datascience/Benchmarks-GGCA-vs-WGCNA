import os
import pandas as pd
import math
import argparse

parser = argparse.ArgumentParser(description='Procesar datasets para generar data subsets con un numero de combinaciones especifico.')
parser.add_argument('--dataset_1', type=str, required=True, help='El nombre del dataset 1 de entrada')
parser.add_argument('--dataset_2', type=str, required=True, help='El nombre del dataset 2 de entrada')
parser.add_argument('--combinations', type=int, required=True, help='El numero de combinaciones al hacer correlacion entre los datasets')

args = parser.parse_args()

import pandas as pd
import numpy as np


def modify_datasets(data1_path, data2_path, C: int):
    data1 = pd.read_csv(data1_path, sep='\t')
    data2 = pd.read_csv(data2_path, sep='\t')

    print(f"INFO\tDATASE1: nFilas: {data1.shape[0]} - nColumnas: {data1.shape[1]}")
    print(f"INFO\tDATASE2: nFilas: {data2.shape[0]} - nColumnas: {data2.shape[1]}")


    c = data1.shape[0] * data2.shape[0]  
    print(f"INFO\tnumero de combinaciones posibles con los datasets sin modificar: {c}")

    if data1.shape[1] != data2.shape[1]:
        print(f"El numero de muestras en el dataset 1 ({data1.shape[1]}) es diferente al del dataset 2 ({data2.shape[1]}).")
        exit(0)
    
    num_rows = int(math.floor(math.sqrt(C))) # obtengo el numeor de filas que necesito de cada dataset

    print(f"INFO\tnumero de filas necesarias de cada dataset: {num_rows}")

    if data1.shape[0] < num_rows:
        print(f"No hay suficientes filas en el conjunto de datos 1 ({data1.shape[0]}) para alcanzar el número de combinaciones deseado ({C}).")
        exit(0)
    if data2.shape[0] < num_rows:
        print(f"No hay suficientes filas en el conjunto de datos 2 ({data2.shape[0]}) para alcanzar el número de combinaciones deseado ({C}).")
        exit(0)

    data1 = data1.head(num_rows)
    data2 = data2.head(num_rows)

    c = data1.shape[0] * data2.shape[0] 
    if c == C:
        print(f"INFO\tnumero de combinaciones posibles con los datasets modificados: {c}")
    else:
        print(f"WARNING\tnumero de combinaciones posibles con los datasets modificados: {c}")
   
    nombre_archivo1_sin_sufijo, extension_archivo1 = os.path.splitext(data1_path)
    nombre_archivo2_sin_sufijo, extension_archivo2 = os.path.splitext(data2_path)

    data1.to_csv(f"{nombre_archivo1_sin_sufijo}_{C}.{extension_archivo1}", index=False, sep='\t')
    data2.to_csv(f"{nombre_archivo2_sin_sufijo}_{C}.{extension_archivo2}", index=False, sep='\t')


modify_datasets(args.dataset_1, args.dataset_1, args.combinations)

