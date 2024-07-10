import pandas as pd
import argparse

parser = argparse.ArgumentParser(description='Procesar dataset para agregar sufijos a valores repetidos en la columna Hugo_Symbol.')
parser.add_argument('--input_file', type=str, required=True, help='El dataset de entrada')
parser.add_argument('--output_file', type=str, required=True, help='El dataset de salida')
args = parser.parse_args()

df = pd.read_csv(args.input_file, sep='\t')

# Diccionario para contar repeticiones
repeticiones = {}

def agregar_sufijo(valor):
    """ Función para agregar sufijos incrementales """
    if valor in repeticiones:
        repeticiones[valor] += 1
        return f"{valor}_{repeticiones[valor]}"
    else:
        repeticiones[valor] = 0
        return valor

# Aplico la función a la primera columna
df.iloc[:, 0] = df.iloc[:, 0].apply(agregar_sufijo)

df.to_csv(args.output_file, sep='\t', index=False, )
