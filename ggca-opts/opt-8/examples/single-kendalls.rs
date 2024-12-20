use ggca::adjustment::AdjustmentMethod;
use ggca::analysis::Analysis;
use ggca::correlation::CorrelationMethod;
use pyo3::PyResult;
use std::time::Instant;
use std::env;

fn main() -> PyResult<()> {
	pyo3::prepare_freethreaded_python();

    // Datasets's paths
	let args: Vec<String> = env::args().collect();
    let threads: usize = (&args[1]).parse().expect("T expected");
    rayon::ThreadPoolBuilder::new().num_threads(threads).build_global().unwrap();

    let gene_file_path = (&args[3]).to_string();
    let gem_file_path = (&args[2]).to_string();

    // Some parameters
    let gem_contains_cpg = false;
    let is_all_vs_all = true;
    let keep_top_n = Some(10); // Keeps the top 10 of correlation (sorting by abs values)
    let collect_gem_dataset = Some(true); // Better performance. Keep small GEM files in memory

    let now = Instant::now();

    // Creates and run an analysis
    let analysis = Analysis {
        gene_file_path,
        gem_file_path,
        gem_contains_cpg,
        correlation_method: CorrelationMethod::Kendall,
        correlation_threshold: 0.5,
        sort_buf_size: 2_000_000,
        adjustment_method: AdjustmentMethod::BenjaminiHochberg,
        is_all_vs_all,
        collect_gem_dataset,
        keep_top_n,
    };

    let (_result, _total_combinations_count, number_of_combinations_evaluated) =
        analysis.compute()?;

    let milliseconds = now.elapsed().as_millis();

	/*
    for cor_p_value in result.iter() {
        println!("{}", cor_p_value);
    } */

    println!(
        "single-kendalls\tggca_opt-8\t{}\t{}\t{}/{}",
        threads,
        milliseconds,
        _total_combinations_count,
        number_of_combinations_evaluated
    );

    Ok(())
}
