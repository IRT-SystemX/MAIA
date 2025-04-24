#!/bin/bash
set -e

java -Xmx${snakemake_params[memory]} -cp ${snakemake_input[maia]} org.maia.run.RunCreateFleet \
    --network-path ${snakemake_input[network]} \
    --demand-path ${snakemake_input[demand]} \
    --output-path ${snakemake_output[0]} \
    --vehicles ${snakemake_params[vehicles]} \
    --capacity ${snakemake_params[capacity]}
