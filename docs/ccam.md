# CCAM simulations for Brussels, Madrid, and Paris

The following sections describe the necessary steps to run the CCAM simulations for the Brussels, Madrid, and Paris use cases.

## Prerequisites

- Please follow the instructions on how to [set up the runtime environment](environment.md). 
- Please follow the instrudictons on how to [generate the demand data](demand.md).

## Network data

To perform the simulation runs, network data for the individual use cases needs to be made available to the processing pipeline. For that, have a look at the guide for [generating the demand data](demand.md) and obtain the OpenStreetMap (OSM) data referenced there. Place the respective data sets into `ccam/resources/{case}/osm` with `case` being any of `paris,madrid,brussels`.

## Running the simulations

After collecting the files, navigate into the `ccam` folder using your command line and execute the following command:

```bash
poetry run snakemake -c1 -s workflow/paris.smk all
```

This will run the whole simulation pipeline for the Paris case. Change the `paris` name in the command line to `brussels` or `madrid` to run the other cases. The simulation will run the following steps:

- Obtain the road network from OpenSteetMap
- Load the demand data. Those data must be placed in `demand/results/{case}/trips/passenger_trips_seed{seed}.gpkg`, i.e., the demand generation pipeline must have been run already.
- Enrich the trip data with service-specific attributes. Those are, for instance, defined in `ccam/resources/paris/enrichment.yml` and analogously for the other cases. They define, in particular, the characteristics of the user profiles (group size distribution, maximum wait time, ...).
- Prepare the relevant data for performing a CCAM simulation (e.g., obtaining a travel time matrix across the network area).
- Perform the simulations which are parameterized by (1) a random seed, (2) a fleet size, (3) a vehicle capacity, (4) and an operating area.

The fleet sizes to be run and the vehicle capacity are defined in `ccam/workflow/paris.smk` whereas the spatial extents are defined in `ccam/resources/paris/spatial.gpkg` and, analogously, for the user cases.

Note that `spatial.gpkg` contains multiple polygons. Each polygon has a `name` that indicates the operating area that the polygon refers to. Furthermore, there is always one polygon called `name="network"` which defines the extent of the routable network that will be extracted from OpenStreetMap data.

The result of each pipeline are MATSim runs located in `ccam/results/{case}/matsim` (for expert users) and aggregated analysis information (using the analysis scripts developed in MAIA) in `ccam/results/{case}/analysis`.

The aggregated outputs can be visualized using the `ccam/Analysis.ipynb` notebook which can be started using standard tools such as VSCode or Jupyter.
