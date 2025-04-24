# MAIA CCAM / Synthetic demand

This repository contains simulation components developed for the [MAIA](https://maiasesarproject.eu/) project which has received funding from the SESAR Joint Untertaking. The focus of the project is to provide the tools to assess the impact and efficiency of Connected Cooperative and Automated Mobility (CCAM) on airport access.

While the MAIA project features various other components, the present repository contains a modeling pipeline to generate a **synthetic travel demand** data set for trips going to and coming from airports, and a component to perform an **agent-based simulation** of a fleet of automated shuttles transporting these travelers while being controlled by a central dispatching algorithm. The agent-based simulation component is based on the open-source [MATSim](http://matsim.org) framework. Both components have been developed by [IRT SystemX](http://irt-systemx.fr) in the scope of the [MAIA](https://maiasesarproject.eu/) project.

## Synthetic travel demand pipeline

The code for the synthetic travel demand pipeline is located in `demand`. It is fully implemented in Python and as a replicable software pipeline based on Snakemake. The pipeline provides various building blocks that allow the user to fuse marginal population data on the area of interest, obtain viable locations for trip origins and destinations, and impute additional attributes to the generate travel demand data. Standardized pipelines are provided for the airports of Brussels (BRU), Madrid (MAD) and Paris (ORY and CDG). 

- [Demand generation for Brussels, Madrid, and Paris](docs/demand.md)

## On-demand fleet simulation pipeline

The code for the agent-based fleet simulations is located in `ccam`. The component is based on the MATSim framework, which is written in Java. Additional scripts are provided which allow for the preparation of input data, such as the demand data from the previous step or road network data from OpenStreetMap. While the individual steps can be run independently, the `ccam` component is also designed as a replicable software pipeline based on Snakemake to allow reuse and ensure reproducibility. The inputs to the pipeline are generic, so it can be run on any of the three use cases provided above and others.

- [CCAM simulations for Brussels, Madrid, and Paris](docs/ccam.md)

## Additional components

While the two above-mentioned components allow for a robust and generic modeling of CCAM airport access services with limited but ubiguitously available data, several additional components have been developed at IRT SystemX to provide a more detailed use case for the use cases of Brussels and Paris. The Brussels case makes use of additional data provided by Brussels Airport during the MAIA project and, hence, can only be used if this data is also available to you. The Paris case is based on a synthetic population of the Île-de-France region and takes into account more detailed information on people volumes at the airports of ORY and CDG throughout the day and applies a simple mode choice model to derive a realistic demand.

- [Extended use case for Brussels](docs/extended/brussels.md)
- [Extended use case for Paris](docs/extended/paris.md)

Furthermore, a case for Madrid is provided that has been elaborated during the MAIA project. It makes us of phone and GPS data collected by Nommnon for the case of Madrid airport:

- [Extended use case for Marid](docs/extended/madrid.md)

## Publications

The results of the extended use case for Paris have been documented in the following publication:

> Declercq, S., Hörl, S., Chouaki, T. (2024), [Towards simulation-based assessment of CCAM Airport Access Services](https://hal.science/hal-04678745v1), paper presented at the 26th Euro Working Group on Transportation Meeting (EWGT), September 2024, Lund, Sweden. 

## Acknowledgements

The MAIA project has received funding from the SESAR Joint Undertaking (JU) under grant agreement No 101114853. The JU receives support from the European Union's Horizon 2020 research and innovation programme and the SESAR JU members other than the Union. The content of this documentation does not reflect the official opinion of the funding institutions. Responsibility for the information and views expressed here lies entirely with the authors.
