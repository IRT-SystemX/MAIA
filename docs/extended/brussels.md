# Extended case for Brussels

This document describes how to set up the extended case for Brussels that has been set up in the MAIA project. Compared to the open-data case, various proprietary data sets from Brussels Airport, partially preprocessed by TML, are used to generate a much more detailed trip data set. Specifically, it follows the sociodemographic characteristics that are observed for travellers at Brussels Airport in real, as well as the correct distribution of luggage or group sizes.

## Preparation

To prepare the extended use case, the instructions set up the [open data use case](../demand.md) for Brussels should be followed. In particular, the data should have been downloaded and the execution environment should have been set up such that the simple pipeline could successfully be run. 

To prepare the extended use case, copy the data that has been collected for the simple use case in `demand/resources/brussels` to the new location in `extended/brussels/resources/brussels`. Additional open and proprietary data sets need to be put in the right place.

The proprietary data sets in can be obtained from Brussels Airport and TML:
- **Post codes**: `Postcode.zip` should contain the shapes of all post codes in Belgium.
- **Passenger volumes**: `airport/2023.Departure.aggregate.xlsx` and `airport/2023.Arrival.aggregate.xlsx` contain information on the Brussels airport passenger volumes by date in 2023.
- **Cabin class and departure hour**: `airport/Aggregated_Departure_Times_by_Cabin_Class.csv` should contain the number of passengers in Brussels airport's passenger survey by cabin class and departure hour
- **Province and cabin class**: `airport/trip_frequency_distribution_per_province_cabin_class.xlsx` should contain information from Brussels airport's passenger on the passenger volumes by origin/destination province and cabin class.
- **Group size**: `airport/group_size_surveys_TML.csv` should contain information on the distribution of group sizes of passengers at Brussels airport.
- **Luggage size and cabin class**: `airport/luggage_distribution_per_province_cabin_class.xlsx` should contain information on the passenger volumes by number of luggage items and cabin class.
- **Parking**: `airport/Grouped_Parking_Data.csv` should contain information about how many people do or don't use parking at Brussels airport, by origin/destination province.
- **Sociodemographics**: `airport/resp_by_mun_age_sex_TML.csv` should contain information from the Brussels airport passenger survey on the number of passengers by origin/destination municipality, age, and sex.
- **Purpose**: `airport/trip_purpuse_distribution_per_province_cabin_class.xlsx` should contain information about the passenger volumes by cabin class and the indicated trip purpose (Leisure / Business).

## Demand generation

After collecting the files, navigate into the `extended/brussels` folder using your command line and execute the following command:

```bash
poetry run snakemake -c 12 -s workflow/demand.smk
```

You can replace the value `12` with the number of cores you want to use. The pipeline will run all models step by step and place all intermediate and the final outputs into `extended/brussels/results/brussels`. In particular, you will find `extended/brussels/results/brussels/trips/passenger_trips_seed0.gpkg`, which is final demand data. It contains a list of trips from and to the airport with per-person attributes and the trips' origins and destinations encoded as a geographic line. This file can be read using Python tools such as `geopandas` or directly be visualized GIS tools such as QGIS.

Additionally, the extended case generates the whole output in *Excel* format (in the same folder as the *GPKG* files). Those files are then used by the downstream mode choice pipeline developed by TML in the scope of MAIA.

## CCAM simation

The resulting files from the mode choice pipeline should be placed into `extended/brussels/results/brussels/mode_choice` following the pattern `TODO.xlsx`. The process for running the simulation is the same as for the [open data use case](../demand.md) but demand samples will be drawn from the mode choice data. To run the simulations, call

```bash
poetry run snakemake -c1 -s workflow/ccam.smk
```

in `extended/brussels`. As for the standard case, the aggregated outputs can be visualized using the `ccam/Analysis.ipynb` notebook which can be started using standard tools such as VSCode or Jupyter.
