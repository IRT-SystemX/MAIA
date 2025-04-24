### MAIA-Engine PAR

# Process open population data

rule prepare_iris_data:
    input: "resources/paris/census/base-ic-evol-struct-pop-2019_csv.zip"
    output: "results/paris/census/iris.parquet"
    notebook: "notebooks/cases/paris/census/Prepare IRIS data.ipynb"

rule prepare_spatial_data:
    input: "resources/paris/census/CONTOURS-IRIS_2-1__SHP__FRA_2021-01-01.7z"
    output: "results/paris/census/spatial.parquet"
    notebook: "notebooks/cases/paris/census/Prepare spatial data.ipynb"

# Process OpenStreetMap

rule extract_buildings:
    input: 
        osm="resources/paris/osm/ile-de-france-latest.osm.pbf",
        zones="results/paris/census/spatial.parquet"
    params:
        zone_attribute="iris_id"
    output: "results/paris/osm/locations.parquet"
    notebook: "notebooks/osm/Extract buildings.ipynb"

# Process proprietary airport data

rule prepare_daily_total:
    output: "results/paris/airport/daily_totals.parquet"
    params: total=237000
    notebook: "notebooks/airport/Prepare daily total.ipynb"

rule prepare_group_size:
    output: "results/paris/airport/group_sizes.parquet"
    notebook: "notebooks/airport/Prepare group size.ipynb"

rule prepare_passenger_profiles:
    output: "results/paris/airport/passenger_profiles.parquet"
    notebook: "notebooks/airport/Prepare passenger profile.ipynb"

rule prepare_departure_hours:
    output: "results/paris/airport/departure_hours.parquet"
    notebook: "notebooks/airport/Prepare departure hour.ipynb"

# Prepare fitting marginals

rule prepare_marginals:
    input:
        iris="results/paris/census/iris.parquet",
        daily="results/paris/airport/daily_totals.parquet",
        group_sizes="results/paris/airport/group_sizes.parquet",
        locations="results/paris/osm/locations.parquet"
    output:
        iris="results/paris/marginals/iris.parquet",
        passengers="results/paris/marginals/passengers.parquet",
        young="results/paris/marginals/young_passengers.parquet",
        missing_locations="results/paris/marginals/missing_locations.parquet"
    notebook: "notebooks/cases/paris/Prepare marginals.ipynb"

# Perform Iterative Proprtional Fitting

rule initialize_population:
    input: "results/paris/census/iris.parquet"
    params:
        attributes=["iris_id", "sex", "age_class"]
    output: "results/paris/population/initial_population.parquet"
    notebook: "notebooks/population/Initialize population.ipynb"

rule iterative_proportional_fitting:
    input:
        seed="results/paris/population/initial_population.parquet",
        marginal_iris="results/paris/marginals/iris.parquet",
        marginal_passengers="results/paris/marginals/passengers.parquet",
        marginal_young_passengers="results/paris/marginals/young_passengers.parquet",
        marginal_missing_locations="results/paris/marginals/missing_locations.parquet"
    output: "results/paris/population/weighted_population.parquet"
    notebook: "notebooks/population/Iterative Proportional Fitting.ipynb"

# Discretize population / passengers

rule discretize_population:
    input:
        population="results/paris/population/weighted_population.parquet",
        spatial="results/paris/census/spatial.parquet"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 1,
        only_passengers=False
    output: "results/paris/population/discretized_population_seed{seed}.parquet"
    notebook: "notebooks/population/Discretize population.ipynb"

rule discretize_passengers:
    input:
        population="results/paris/population/weighted_population.parquet",
        spatial="results/paris/census/spatial.parquet"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 2,
        only_passengers=True
    output: "results/paris/population/discretized_passengers_seed{seed}.parquet"
    notebook: "notebooks/population/Discretize population.ipynb"

# Spatial localization of persons

rule localize_passengers:
    input:
        passengers="results/paris/population/discretized_passengers_seed{seed}.parquet",
        locations="results/paris/osm/locations.parquet"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 3,
        zone_attribute="iris_id"
    output: "results/paris/population/localized_passengers_seed{seed}.parquet"
    notebook: "notebooks/population/Localize population (location-based).ipynb"

# Enrichment of the passenger population

rule enrich_group_size:
    input:
        target="results/paris/population/localized_passengers_seed{seed}.parquet",
        distribution="results/paris/airport/group_sizes.parquet"
    params:
        attributes=["group_size"],
        seed=lambda wildcards: int(wildcards["seed"]) + 4
    output: "results/paris/population/passengers_with_group_size_seed{seed}.parquet"
    notebook: "notebooks/population/Perform enrichment.ipynb"

rule enrich_passenger_profile:
    input:
        target="results/paris/population/passengers_with_group_size_seed{seed}.parquet",
        distribution="results/paris/airport/passenger_profiles.parquet"
    params:
        attributes=["passenger_profile"],
        seed=lambda wildcards: int(wildcards["seed"]) + 5
    output: "results/paris/population/passengers_with_profile_seed{seed}.parquet"
    notebook: "notebooks/population/Perform enrichment.ipynb"

rule enrich_departure_hour:
    input:
        target="results/paris/population/passengers_with_profile_seed{seed}.parquet",
        distribution="results/paris/airport/departure_hours.parquet"
    params:
        attributes=["departure_hour"],
        seed=lambda wildcards: int(wildcards["seed"]) + 6
    output: "results/paris/population/passengers_with_departure_hour_seed{seed}.parquet"
    notebook: "notebooks/population/Perform enrichment.ipynb"

# Generate trips with origins, destinations, and departure time

rule generate_trips:
    input:
        passengers="results/paris/population/passengers_with_departure_hour_seed{seed}.parquet",
        airports="resources/paris/airport/locations.gpkg"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 7
    output: "results/paris/trips/passenger_trips_seed{seed}.{ext}"
    notebook: "notebooks/trips/Generate trips.ipynb"

# Default rule to generate population and passenger trips

rule all:
    input:
        "results/paris/population/discretized_population_seed1000.parquet",
        "results/paris/trips/passenger_trips_seed1000.gpkg"
    default_target: True
