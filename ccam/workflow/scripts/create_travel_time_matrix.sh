#!/bin/bash
set -e

java -Xmx${snakemake_params[memory]} -cp ${snakemake_input[maia]} org.maia.run.RunCreateTravelTimeMatrix \
    --network-path ${snakemake_input[network]} \
    --output-path ${snakemake_output[0]} \
    --threads ${snakemake_params[threads]} \
    --cell-size ${snakemake_params[cellsize]}
