## MAIA-Engine data generation

module brussels:
    snakefile: "brussels.smk"
    config: config

module madrid:
    snakefile: "madrid.smk"
    config: config

module paris:
    snakefile: "paris.smk"
    config: config

use rule * from brussels as brussels_*
use rule * from madrid as madrid_*
use rule * from paris as paris_*

rule all:
    input: 
        expand("results/{case}/trips/passenger_trips_seed{seed}.gpkg", 
            case = ["paris", "madrid", "brussels"], seed = range(0, 10000, 1000))
    default_target: True
