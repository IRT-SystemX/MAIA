# Extended case for Paris

This document describes how to set up the extended demand case for Paris that has been set up in the MAIA project. It makes use of an already existing synthetic population form the [eqasim](https://github.com/eqasim-org/ile-de-france) project.

## Preparation

To prepare the extended use case, you need to obtain a synthetic population for the Île-de-France region as described [here](https://github.com/eqasim-org/ile-de-france). In particular, you should run that pipeline including the generation of a MATSim simulation. This way, the required data for the public transport network will be generated as well. Put all the output data into `extended/paris/resources/eqasim`.

## Demand generation

After collecting the files, navigate into the `extended/paris` folder using your command line and execute the following command:

```bash
poetry run snakemake -c 12 -s workflow/demand.smk
```

The pipeline will perform the following steps:

1. The files in `resources/demand/{ory,cdg}.yml` define key characteristics for the demand at the two airports: The share of `leisure`, `business`, `premium` passengers, the daily distribution of their arrivals and departures, the overall number of passengers at the airport, and others. Using this information, a basic demand data set is generated: where are the origins and destinations of the passengers.

2. All resulting access/egress trips to the airport are routed on the Île-de-France road network and on the transit network. This way, we obtain road travel times, public transport travel times and other characteristics that influence the choice of persons.

3. The parameters (in particular, valuation of travel time by user profile) of the choice model are given in `resources/scenarios/*.yml`. They are obtained from a value-of-time study for France (Meunier and Quinet, 2025). Furthermore, cost parameteters for the individual modes are given, and alternative scenarios can be created by adding more `yml` files in that folder. The choice model is calibrated to obtain certain *target* mode shares that are also given in the files and which are national averages for airport access trips in France. The mode-specific constants of the applied multinomial logit model are automatically calibrated to obtain those mode shares. Finally, a choice of mode is made for each trip.

4. Finally, the trips for a specific mode (taxi or CCAM) are extracted so they can be used in the downstream fleet simulation.

The whole process is described in detail in 

> Declercq, S., Hörl, S., Chouaki, T. (2024), [Towards simulation-based assessment of CCAM Airport Access Services](https://hal.science/hal-04678745v1), paper presented at the 26th Euro Working Group on Transportation Meeting (EWGT), September 2024, Lund, Sweden. 

## CCAM simulation

To run the simulations for Paris call

```bash
poetry run snakemake -c1 -s workflow/ccam.smk
```

in `extended/paris`. As for the standard case, the aggregated outputs can be visualized using the `ccam/Analysis.ipynb` notebook which can be started using standard tools such as VSCode or Jupyter.
