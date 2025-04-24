# Demand generation for Brussels, Madrid, and Paris

The following sections describe the necessary steps to run the standard demand generation pipelines for the Brussels, Madrid, and Paris use cases. Note that this guide creates demand data sets with default distributions for passenger profiles, departure times, group sizes and per-airport daily passenger counts.

## Prerequisites

Please follow the instructions on how to [set up the runtime environment](environment.md). The dependency management system that is used for the synthetic population process is `poetry`. [Snakemake](https://snakemake.readthedocs.io) is the pipeline orchestration tool that is used in this project and which makes sure that the individual modeling steps are called one after another. It should be installed automatically in a properly configured environment.

## Brussels

To generate the synthetic demand for Brussels, the required input data sets need to be collected. The first group of data sets is population data. All downloaded files should be placed into `demand/resources/brussels/census`:

- [Population size by statistical sector](https://statbel.fgov.be/en/open-data/population-statistical-sector-11): Follow the link and download the file noted as *TXT (ZIP)* at the bottom of the page.
- [Population size by sociodemographics and municipality](https://statbel.fgov.be/en/open-data/population-place-residence-nationality-marital-status-age-and-sex-13): Download the file noted as *TXT (ZIP)*.
- [Geographical definition of statistical sectors](https://statbel.fgov.be/en/open-data/statistical-sectors-2023): Follow the link and download the file noted as *shp (ZIP)* at the bottom of the page.

Next, data describing the buildings of the area need to be obtained. For that, OpenStreetMap is used. The downloaded file should be placed into `demand/resources/brussels/osm`:

- [OSM cut-out for Belgium](https://download.geofabrik.de/europe/belgium.html): Download the latest version in *osm.pbf* format.

After collecting the files, navigate into the `demand` folder using your command line and execute the following command:

```bash
poetry run snakemake -c 12 -s workflow/brussels.smk all
```

You can replace the value `12` with the number of cores you want to use. The pipeline will run all models step by step and place all intermediate and the final outputs into `demand/results/brussels`. In particular, you will find `results/brussels/trips/passenger_trips_seed0.gpkg`, which is final demand data. It contains a list of trips from and to the airport with per-person attributes and the trips' origins and destinations encoded as a geographic line. This file can be read using Python tools such as `geopandas` or directly be visualized GIS tools such as QGIS.

For Brussels (see `workflow/brussels.smk`), a total number of passengers per day of 61,000 is assumed.

Note that for many important aspects of the demand, default data sets are used (such as the temporal distribution). An [extended version](extended/brussels.md) is available for users that have access to specific proprietary data from Brussels airport.

## Madrid

To generate the synthetic demand for Madrid, the required input data sets need to be collected. The first group of data sets is population data. All downloaded files should be placed into `demand/resources/madrid/census`:

- [Population characteristics by municipality](https://datos.gob.es/es/catalogo/ea0010587-poblacion-por-sexo-y-edad-ano-a-ano-identificador-api-68542): Click on the *csv* version for the second data set in the list (*CSV: separado por tabuladores*) and put the *csv* file into the folder.
- [Geographical definition of administrative zones](https://centrodedescargas.cnig.es/CentroDescargas/catalogo.do?Serie=LILIM): Follow the link and download the file *
Límites y Unidades Administrativas*. Put the *zip* file into the folder.

Next, data describing the buildings of the area need to be obtained. For that, OpenStreetMap is used. The downloaded file should be placed into `demand/resources/madrid/osm`:

- [OSM cut-out for Île-de-France](https://download.geofabrik.de/europe/spain/madrid.html): Download the latest version in *osm.pbf* format.

After collecting the files, navigate into the `demand` folder using your command line and execute the following command:

```bash
poetry run snakemake -c 12 -s workflow/madrid.smk all
```

You can replace the value `12` with the number of cores you want to use. The pipeline will run all models step by step and place all intermediate and the final outputs into `demand/results/madrid`. In particular, you will find `results/madrid/trips/passenger_trips_seed0.gpkg`, which is final demand data. It contains a list of trips from and to the airport with per-person attributes and the trips' origins and destinations encoded as a geographic line. This file can be read using Python tools such as `geopandas` or directly be visualized GIS tools such as QGIS.

For Madrid (see `workflow/madrid.smk`), a total number of passengers per day of 167,000 is assumed.

## Paris

To generate the synthetic demand for Paris, the required input data sets need to be collected. The first group of data sets is population data. All downloaded files should be placed into `demand/resources/paris/census`:

- [Population characteristics by municipality](https://www.insee.fr/fr/statistiques/6456153?sommaire=6456166): Click on the *csv* version for the first data set in the list (*Évolution et structure de la population en 2019*) and put the *zip* file into the folder.
- [Geographical definition of statistical sectors](https://geoservices.ign.fr/contoursiris): Follow the link and download the version indicated as *Contours IRIS® édition 2021*. Put the *z7* file into the folder.

Next, data describing the buildings of the area need to be obtained. For that, OpenStreetMap is used. The downloaded file should be placed into `demand/resources/paris/osm`:

- [OSM cut-out for Île-de-France](https://download.geofabrik.de/europe/france/ile-de-france.html): Download the latest version in *osm.pbf* format.

After collecting the files, navigate into the `demand` folder using your command line and execute the following command:

```bash
poetry run snakemake -c 12 -s workflow/paris.smk all
```

You can replace the value `12` with the number of cores you want to use. The pipeline will run all models step by step and place all intermediate and the final outputs into `demand/results/paris`. In particular, you will find `results/paris/trips/passenger_trips_seed0.gpkg`, which is final demand data. It contains a list of trips from and to the airport with per-person attributes and the trips' origins and destinations encoded as a geographic line. This file can be read using Python tools such as `geopandas` or directly be visualized GIS tools such as QGIS.

For Paris (see `workflow/paris.smk`), a total number of passengers per day of 237,000 is assumed. Note that these are distributed over the airports CDG and ORY according to the ratio defined in `resources/paris/airport/locations.gpkg`.

Note that for many important aspects of the demand, default data sets are used (such as the temporal distribution). An [extended version](extended/paris.md) is available for users that have access to specific proprietary data from Paris airport.

## Generate all demand

There is a convenience script which will create 10 samples for the three airports:

```bash
poetry run snakemake -c 12 -s workflow/maia.smk all
```
