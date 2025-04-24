## MAIA-Engine data generation

module demand:
    snakefile: "demand.smk"
    config: config

use rule * from demand as demand_*

rule generate_samples:
    input: expend("results/brussels/trips/passenger_trips_seed{}.xlsx", seed = range(0, 10000, 1000))
    default_target: True
