#!/bin/bash
set -e

java -Xmx${snakemake_params[memory]} -cp ${snakemake_input[maia]} org.maia.run.RunCreateDemand \
    --demand-path ${snakemake_input[demand]} \
    --output-path ${snakemake_output[0]}
