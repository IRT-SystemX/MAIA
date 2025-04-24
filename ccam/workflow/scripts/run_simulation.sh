#!/bin/bash
set -e

java -Xmx${snakemake_params[memory]} -cp ${snakemake_input[maia]} org.maia.run.RunSimulation \
    --network-path ${snakemake_input[network]} \
    --demand-path ${snakemake_input[demand]} \
    --fleet-path ${snakemake_input[fleet]} \
    --travel-time-matrix-path ${snakemake_input[travel_time_matrix]} \
    --output-path ${snakemake_output[0]} \
    --threads ${snakemake_params[threads]} \
    --cell-size ${snakemake_params[cellsize]}
