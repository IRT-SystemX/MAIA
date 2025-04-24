# Extended case for Madird

This document describes how to set up the extended case for Madrid that has been set up in the MAIA project. Compared to the open-data case, various proprietary data sets from Madrid, especially user data of a shared mobility services, have been processed by Nommon.

## Preparation

To prepare the extended use case, the instructions set up the [open data use case](../demand.md) for Madrid should be followed. In particular, the data should have been downloaded and the execution environment should have been set up such that the simple pipeline could successfully be run. 

## Demand data

Place the demand data provided by Nommon into `extended/madrid/resources/demand` and then call the following pipeline inside `extended/madrid` to convert the data into the right format:

```bash
poetry run snakemake -c 12 -s workflow/demand.smk
```

## CCAM simation

After, the CCAM simulations can be run by calling:

```bash
poetry run snakemake -c1 -s workflow/ccam.smk
```

in `extended/madrid`. As for the standard case, the aggregated outputs can be visualized using the `ccam/Analysis.ipynb` notebook which can be started using standard tools such as VSCode or Jupyter.
