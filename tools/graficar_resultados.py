import os
import sys
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd


archivo_tsv = sys.argv[1]
data = pd.read_csv(archivo_tsv, sep='\t')
grouped_data = data.groupby(['Dataset', 'Algorithm', 'Optimization', 'Threads'], as_index=False)['Finished time (ms)'].mean()

# Estilo
sns.set_theme(style="whitegrid")

def guardar_grafico(plot, nombre):
    plot.savefig(nombre)
    plot.close()
    print(f"Grafico guardado: {nombre}")


def create_individual_benchmark_boxplots_times(data):
    """ Funcion para crear graficos que describan la informacion a nivel general """
    unique_algorithms = data['Algorithm'].unique()
    unique_threads = data['Threads'].unique()
    unique_datasets = data['Dataset'].unique()
    
    for algorithm in unique_algorithms:
        for thread in unique_threads:
            for dataset in unique_datasets:
                # Filtrar los datos para la combinación actual
                subset = data[(data['Algorithm'] == algorithm) &
                              (data['Threads'] == thread) &
                              (data['Dataset'] == dataset)]
                
                if not subset.empty:
                    plt.figure(figsize=(12, 6))
                    sns.boxplot(x='Optimization', y='Finished time (ms)', hue='Optimization', data=subset, palette="viridis", legend=False)
                    
                    plt.title('Distribución de Tiempos de Finalización por Optimización')
                    plt.xlabel('Optimization')
                    plt.ylabel('Finished time (ms)')
                    plt.xticks(rotation=45)
                    plt.tight_layout()
                    
                    # Guardar la gráfica
                    directorio = "graficos/boxplots"
                    os.makedirs(directorio) if not os.path.exists(directorio) else None
                    filename = f'{directorio}/algorithm_{algorithm}_threads_{thread}_dataset_{dataset}_boxplot.png'
                    guardar_grafico(plt, filename)


def create_individual_benchmark_violinplots_times(data):
    """ Funcion para crear graficos que describan la informacion a nivel general """
    unique_algorithms = data['Algorithm'].unique()
    unique_threads = data['Threads'].unique()
    unique_datasets = data['Dataset'].unique()
    
    for algorithm in unique_algorithms:
        for thread in unique_threads:
            for dataset in unique_datasets:
                # Filtrar los datos para la combinación actual
                subset = data[(data['Algorithm'] == algorithm) &
                              (data['Threads'] == thread) &
                              (data['Dataset'] == dataset)]
                
                if not subset.empty:
                    plt.figure(figsize=(12, 6))
                    sns.violinplot(x='Optimization', y='Finished time (ms)', hue='Optimization', data=subset, palette="viridis")
                    sns.despine(offset=10, trim=True)
                    # sns.boxplot(x='Optimization', y='Finished time (ms)', hue='Optimization', data=subset, palette="viridis", legend=False)
                    
                    plt.title('Distribución de Tiempos de Finalización por Optimización')
                    plt.xlabel('Optimization')
                    plt.ylabel('Finished time (ms)')
                    plt.xticks(rotation=45)
                    plt.tight_layout()
                    
                    # Guardar la gráfica
                    directorio = "graficos/violinplots"
                    os.makedirs(directorio) if not os.path.exists(directorio) else None
                    filename = f'{directorio}/algorithm_{algorithm}_threads_{thread}_dataset_{dataset}_violinplot.png'
                    guardar_grafico(plt, filename)


def compare_optimizations_threads(grouped_data):
    """ Crea graficas para comparar optimizaciones según los threads """
    unique_algorithms = grouped_data['Algorithm'].unique()
    unique_datasets = grouped_data['Dataset'].unique()
    
    for algorithm in unique_algorithms:
        for dataset in unique_datasets:
            # Filtrar los datos para la combinación actual
            subset = grouped_data[(grouped_data['Algorithm'] == algorithm) &
                          (grouped_data['Dataset'] == dataset)]
            
            if not subset.empty:
                plt.figure(figsize=(14, 8))
                # Crear gráfico de barras agrupadas
                sns.barplot(x='Optimization', y='Finished time (ms)', hue='Threads', data=subset, palette="viridis")
                
                plt.title(f'{algorithm} - Dataset {dataset}')
                plt.xlabel('Optimization')
                plt.ylabel('Finished time (ms)')
                plt.xticks(rotation=45)
                plt.legend(title='Threads')
                plt.tight_layout()
                
                # Guardar la gráfica
                directorio = "graficos/comparacion_por_threads"
                os.makedirs(directorio) if not os.path.exists(directorio) else None
                filename = f'{directorio}/algorithm_{algorithm}_dataset_{dataset}_comparison_threads.png'
                guardar_grafico(plt, filename)


def compare_optimizations_datasets(grouped_data):
    """ Crea graficas para comparar optimizaciones según los datasets """
    unique_algorithms = grouped_data['Algorithm'].unique()
    unique_threads = grouped_data['Threads'].unique()
    
    for algorithm in unique_algorithms:
        for thread in unique_threads:
            # Filtrar los datos para la combinación actual
            subset = grouped_data[(grouped_data['Algorithm'] == algorithm) &
                                  (grouped_data['Threads'] == thread)]
            
            if not subset.empty:
                plt.figure(figsize=(14, 8))
                # Crear gráfico de barras agrupadas
                sns.barplot(x='Optimization', y='Finished time (ms)', hue='Dataset', data=subset, palette="viridis")
                
                plt.title(f'{algorithm} - {thread} Threads - Comparación de Datasets')
                plt.xlabel('Optimization')
                plt.ylabel('Finished time (ms)')
                plt.xticks(rotation=45)
                plt.legend(title='Dataset')
                plt.tight_layout()
                
                # Guardar la gráfica
                directorio = "graficos/comparacion_por_datasets"
                os.makedirs(directorio) if not os.path.exists(directorio) else None
                filename = f'{directorio}/algorithm_{algorithm}_threads_{thread}_comparison_datasets.png'
                guardar_grafico(plt, filename)


def compare_optimizations_all_algorithms(grouped_data):
    """ Crea graficas para comparar optimizaciones según los algoritmos """
    unique_threads = grouped_data['Threads'].unique()
    unique_datasets = grouped_data['Dataset'].unique()
    
    for thread in unique_threads:
        for dataset in unique_datasets:
            # Filtrar los datos para la combinación actual
            subset = grouped_data[(grouped_data['Threads'] == thread) &
                          (grouped_data['Dataset'] == dataset)]
            
            if not subset.empty:
                plt.figure(figsize=(14, 8))
                # Crear gráfico de barras agrupadas
                sns.barplot(x='Optimization', y='Finished time (ms)', hue='Algorithm', data=subset, palette="viridis")
                
                plt.title(f'{thread} - Dataset {dataset}')
                plt.xlabel('Optimization')
                plt.ylabel('Finished time (ms)')
                plt.xticks(rotation=45)
                plt.legend(title='Threads')
                plt.tight_layout()
                
                # Guardar la gráfica
                directorio = "graficos/comparacion_por_algoritmos"
                os.makedirs(directorio) if not os.path.exists(directorio) else None
                filename = f'{directorio}/threads_{thread}_dataset_{dataset}_comparison_algorithm.png'
                guardar_grafico(plt, filename)


def compare_optimizations_Algorithm(grouped_data):
    """ Crea gráficas individuales para comparar optimizaciones según los algoritmos. """
    unique_threads = grouped_data['Threads'].unique()
    unique_datasets = grouped_data['Dataset'].unique()
    unique_algorithms = grouped_data['Algorithm'].unique()
    directorio = "graficos/comparacion_por_algoritmos_individuales"
    os.makedirs(directorio, exist_ok=True)

    for algorithm in unique_algorithms:
        subset_algorithm = grouped_data[grouped_data['Algorithm'] == algorithm]
        
        if not subset_algorithm.empty:
            plt.figure(figsize=(14, 8))
            for thread in unique_threads:
                for dataset in unique_datasets:
                    subset = subset_algorithm[(subset_algorithm['Threads'] == thread) & (subset_algorithm['Dataset'] == dataset)]
                    
                    if not subset.empty:
                        sns.barplot(x='Optimization', y='Finished time (ms)', hue='Optimization', legend=False, data=subset, label=f'Threads {thread} - Dataset {dataset}', palette="viridis")
            plt.title(f'Algorithm: {algorithm}')
            plt.xlabel('Optimization')
            plt.ylabel('Finished time (ms)')
            plt.xticks(rotation=45)
            plt.legend(title='Threads and Datasets', bbox_to_anchor=(1.05, 1), loc='upper left')
            plt.tight_layout()
            
            filename = f'{directorio}/algorithm_{algorithm}_comparison.png'
            guardar_grafico(plt, filename)

create_individual_benchmark_boxplots_times(data)
create_individual_benchmark_violinplots_times(data)
compare_optimizations_threads(data)
compare_optimizations_datasets(grouped_data)
compare_optimizations_all_algorithms(grouped_data)
compare_optimizations_Algorithm(grouped_data)