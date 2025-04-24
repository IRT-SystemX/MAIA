### MAIA-Engine BRU

# Process open population data

rule prepare_municipality_data:
    input: "resources/brussels/census/TF_SOC_POP_STRUCT_2023.zip"
    output: "results/brussels/census/municipalities.parquet"
    notebook: "notebooks/cases/brussels/census/Prepare municipality data.ipynb"

rule prepare_sector_data:
    input: "resources/brussels/census/OPENDATA_SECTOREN_2023.zip"
    output: "results/brussels/census/sectors.parquet"
    notebook: "notebooks/cases/brussels/census/Prepare sector data.ipynb"

rule prepare_spatial_data:  
    input: 
        data="resources/brussels/census/sh_statbel_statistical_sectors_3812_20230101.shp.zip",
        sectors="results/brussels/census/sectors.parquet"
    output: "results/brussels/census/spatial.parquet"
    notebook: "notebooks/cases/brussels/census/Prepare spatial data.ipynb"

# Process OpenStreetMap

rule extract_buildings:
    input: 
        osm="resources/brussels/osm/belgium-latest.osm.pbf",
        zones="results/brussels/census/spatial.parquet"
    params:
        zone_attribute="sector_index"
    output: "results/brussels/osm/locations.parquet"
    notebook: "notebooks/osm/Extract buildings.ipynb"

# Process airport data

rule prepare_daily_total:
    output: "results/brussels/airport/daily_totals.parquet"
    params: total=61000
    notebook: "notebooks/airport/Prepare daily total.ipynb"

rule prepare_group_size:
    output: "results/brussels/airport/group_sizes.parquet"
    notebook: "notebooks/airport/Prepare group size.ipynb"

rule prepare_passenger_profiles:
    output: "results/brussels/airport/passenger_profiles.parquet"
    notebook: "notebooks/airport/Prepare passenger profile.ipynb"

rule prepare_departure_hours:
    output: "results/brussels/airport/departure_hours.parquet"
    notebook: "notebooks/airport/Prepare departure hour.ipynb"

# Prepare fitting marginals

rule prepare_marginals:
    input:
        municipalities="results/brussels/census/municipalities.parquet",
        sectors="results/brussels/census/sectors.parquet",
        daily="results/brussels/airport/daily_totals.parquet",
        group_sizes="results/brussels/airport/group_sizes.parquet",
        locations="results/brussels/osm/locations.parquet"
    output:
        municipalities="results/brussels/marginals/municipalities.parquet",
        sectors="results/brussels/marginals/sectors.parquet",
        passengers="results/brussels/marginals/passengers.parquet",
        young="results/brussels/marginals/young_passengers.parquet",
        missing_locations="results/brussels/marginals/missing_locations.parquet"
    notebook: "notebooks/cases/brussels/Prepare marginals.ipynb"

# Perform Iterative Proprtional Fitting

rule initialize_population:
    input:
        "results/brussels/census/sectors.parquet",
        "results/brussels/census/municipalities.parquet"
    params:
        attributes=["municipality_id", "sector_index", "sex", "age_class"]
    output: "results/brussels/population/initial_population.parquet"
    notebook: "notebooks/population/Initialize population.ipynb"

rule iterative_proportional_fitting:
    input:
        seed="results/brussels/population/initial_population.parquet",
        marginal_municipalities="results/brussels/marginals/municipalities.parquet",
        marginal_sectors="results/brussels/marginals/sectors.parquet",
        marginal_passengers="results/brussels/marginals/passengers.parquet",
        marginal_young_passengers="results/brussels/marginals/young_passengers.parquet",
        marginal_missing_locations="results/brussels/marginals/missing_locations.parquet"
    output: "results/brussels/population/weighted_population.parquet"
    notebook: "notebooks/population/Iterative Proportional Fitting.ipynb"

# Discretize passengers / population

rule discretize_population:
    input:
        population="results/brussels/population/weighted_population.parquet",
        spatial="results/brussels/census/spatial.parquet"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 1,
        only_passengers=False
    output: "results/brussels/population/discretized_population_seed{seed}.parquet"
    notebook: "notebooks/population/Discretize population.ipynb" 

rule discretize_passengers:
    input:
        population="results/brussels/population/weighted_population.parquet",
        spatial="results/brussels/census/spatial.parquet"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 2,
        only_passengers=True
    output: "results/brussels/population/discretized_passengers_seed{seed}.parquet"
    notebook: "notebooks/population/Discretize population.ipynb"

# Spatial localization of persons

rule localize_passengers:
    input:
        passengers="results/brussels/population/discretized_passengers_seed{seed}.parquet",
        locations="results/brussels/osm/locations.parquet"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 3,
        zone_attribute="sector_index"
    output: "results/brussels/population/localized_passengers_seed{seed}.parquet"
    notebook: "notebooks/population/Localize population (location-based).ipynb"

# Enrichment of the passenger population

rule enrich_group_size:
    input:
        target="results/brussels/population/localized_passengers_seed{seed}.parquet",
        distribution="results/brussels/airport/group_sizes.parquet"
    params:
        attributes=["group_size"],
        seed=lambda wildcards: int(wildcards["seed"]) + 4
    output: "results/brussels/population/passengers_with_group_size_seed{seed}.parquet"
    notebook: "notebooks/population/Perform enrichment.ipynb"

rule enrich_passenger_profile:
    input:
        target="results/brussels/population/passengers_with_group_size_seed{seed}.parquet",
        distribution="results/brussels/airport/passenger_profiles.parquet"
    params:
        attributes=["passenger_profile"],
        seed=lambda wildcards: int(wildcards["seed"]) + 5
    output: "results/brussels/population/passengers_with_profile_seed{seed}.parquet"
    notebook: "notebooks/population/Perform enrichment.ipynb"

rule enrich_departure_hour:
    input:
        target="results/brussels/population/passengers_with_profile_seed{seed}.parquet",
        distribution="results/brussels/airport/departure_hours.parquet"
    params:
        attributes=["departure_hour"],
        seed=lambda wildcards: int(wildcards["seed"]) + 6
    output: "results/brussels/population/passengers_with_departure_hour_seed{seed}.parquet"
    notebook: "notebooks/population/Perform enrichment.ipynb"

rule finish_enrichment:
    input: "results/brussels/population/passengers_with_departure_hour_seed{seed}.parquet"
    output: "results/brussels/population/passengers_enriched_seed{seed}.parquet"
    shell: "cp {input[0]} {output[0]}"

# Generate trips with origins, destinations, and departure time

rule generate_trips:
    input:
        passengers="results/brussels/population/passengers_enriched_seed{seed}.parquet",
        airports="resources/brussels/airport/location.gpkg"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 13
    wildcard_constraints:
        ext="gpkg|parquet"
    output: "results/brussels/trips/passenger_trips_seed{seed}.{ext}"
    notebook: "notebooks/trips/Generate trips.ipynb"

# Default rule to generate population and passenger trips

rule all:
    input:
        "results/brussels/population/discretized_population_seed1000.parquet",
        "results/brussels/trips/passenger_trips_seed1000.gpkg"
    default_target: True
