### Pipeline to generate demand for the Paris extended case

seeds = list(range(0, 1000, 10000))
prefix = "idf_1pct_"

# Imports
module java:
    snakefile: "../../../ccam/workflow/java.smk"
    config: config

use rule build_eqasim from java
use rule clone_eqasim from java

# Generate a single airport demand
rule generate_demand:
    input:
        homes="resources/eqasim/{prefix}homes.gpkg".format(prefix = prefix),
        airport="resources/demand/{airport}.yml"
    output: "results/demand/airport/{airport}_seed{seed}.gpkg"
    notebook: "notebooks/Generate demand.ipynb"

# Merge multiple airports
rule merge_demand:
    input:
        "results/demand/airport/cdg_seed{seed}.gpkg",
        "results/demand/airport/ory_seed{seed}.gpkg"
    output: "results/demand/merged_seed{seed}.gpkg"
    notebook: "notebooks/Merge demand.ipynb"

# Prepare routing of the demand data sets
rule prepare_routing:
    input: "results/demand/merged_seed{seed}.gpkg"
    output: "results/routing/requests_seed{seed}.json"
    notebook: "notebooks/Prepare routing.ipynb"

# Perform routing
rule perform_routing:
    input: 
        eqasim_idf="results/eqasim_idf.jar",
        eqasim_server="results/eqasim_server.jar",
        requests="results/routing/requests_seed{seed}.json",
        config="resources/eqasim/{prefix}config.xml".format(prefix = prefix)
    threads: 12
    params:
        memory="12g", threads="12"
    output: "results/routing/routes_seed{seed}.json"
    script: "scripts/routing.sh" 

# Perform mode choice
rule perform_mode_choice:
    input:
        scenario="resources/scenarios/{scenario}.yml",
        demand="results/demand/merged_seed{seed}.gpkg",
        routes="results/routing/routes_seed{seed}.json",
    output: "results/mode_choice/{scenario}_seed{seed}.gpkg"
    notebook: "notebooks/Perform mode choice.ipynb"

# Generate all seeds
rule all:
    #input: ["results/demand/merged_seed{seed}.gpkg".format(seed = seed) for seed in seeds]
    input: "results/mode_choice/baseline_seed1000.gpkg"
