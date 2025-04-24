#!/bin/bash
set -e

java -Xmx${snakemake_params[memory]} -cp ${snakemake_input[maia]} org.maia.run.RunConvertNetwork \
    --input-path ${snakemake_input[osm]} \
    --output-path ${snakemake_output[0]} \
    --crs ${snakemake_params[crs]}
