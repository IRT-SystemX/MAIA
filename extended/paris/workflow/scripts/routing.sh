#!/bin/bash
set -e

java -Xmx${snakemake_params[memory]} -cp ${snakemake_input[eqasim_idf]}:${snakemake_input[eqasim_server]} org.eqasim.server.RunProcessor \
    --config-path ${snakemake_input[config]} \
    --threads ${snakemake[threads]} --use-transit false \
    --eqasim-configurator org.eqasim.ile_de_france.IDFConfigurator \
    --input-path ${snakemake_input[requests]} \
    --output-path ${snakemake_output[0]} \
    --config:swissRailRaptor.transferCalculation Adaptive \
    --use-transit true
