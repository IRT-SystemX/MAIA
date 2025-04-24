### MAIA-Engine MAD

# Process open population data

rule prepare_municipality_data:
    input: "resources/madrid/census/68542.csv"
    output: "results/madrid/census/municipalities.parquet"
    notebook: "notebooks/cases/madrid/census/Prepare municipality data.ipynb"

rule prepare_spatial_data:
    input: "resources/madrid/census/lineas_limite.zip"
    output: "results/madrid/census/spatial.parquet"
    notebook: "notebooks/cases/madrid/census/Prepare spatial data.ipynb"

# Process OpenStreetMap

rule extract_buildings:
    input: 
        osm="resources/madrid/osm/madrid-latest.osm.pbf",
        zones="results/madrid/census/spatial.parquet"
    params:
        zone_attribute="municipality_id"
    output: "results/madrid/osm/locations.parquet"
    notebook: "notebooks/osm/Extract buildings.ipynb"

# Process airport data

rule prepare_daily_total:
    output: "results/madrid/airport/daily_totals.parquet"
    params: total=167000
    notebook: "notebooks/airport/Prepare daily total.ipynb"

rule prepare_group_size:
    output: "results/madrid/airport/group_sizes.parquet"
    notebook: "notebooks/airport/Prepare group size.ipynb"

rule prepare_passenger_profiles:
    output: "results/madrid/airport/passenger_profiles.parquet"
    notebook: "notebooks/airport/Prepare passenger profile.ipynb"

rule prepare_departure_hours:
    output: "results/madrid/airport/departure_hours.parquet"
    notebook: "notebooks/airport/Prepare departure hour.ipynb"

# Prepare fitting marginals

rule prepare_marginals:
    input:
        municipalities="results/madrid/census/municipalities.parquet",
        daily="results/madrid/airport/daily_totals.parquet",
        group_sizes="results/madrid/airport/group_sizes.parquet",
        locations="results/madrid/osm/locations.parquet"
    output:
        municipalities="results/madrid/marginals/municipalities.parquet",
        passengers="results/madrid/marginals/passengers.parquet",
        young="results/madrid/marginals/young_passengers.parquet",
        missing_locations="results/madrid/marginals/missing_locations.parquet"
    notebook: "notebooks/cases/madrid/Prepare marginals.ipynb"

# Perform Iterative Proprtional Fitting

rule initialize_population:
    input: "results/madrid/census/municipalities.parquet"
    params:
        attributes=["municipality_id", "sex", "age_class"]
    output: "results/madrid/population/initial_population.parquet"
    notebook: "notebooks/population/Initialize population.ipynb"

rule iterative_proportional_fitting:
    input:
        seed="results/madrid/population/initial_population.parquet",
        marginal_municipalities="results/madrid/marginals/municipalities.parquet",
        marginal_passengers="results/madrid/marginals/passengers.parquet",
        marginal_young_passengers="results/madrid/marginals/young_passengers.parquet",
        marginal_missing_locations="results/madrid/marginals/missing_locations.parquet"
    output: "results/madrid/population/weighted_population.parquet"
    notebook: "notebooks/population/Iterative Proportional Fitting.ipynb"

# Discretize population / passengers

rule discretize_population:
    input:
        population="results/madrid/population/weighted_population.parquet",
        spatial="results/madrid/census/spatial.parquet"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 1,
        only_passengers=False
    output: "results/madrid/population/discretized_population_seed{seed}.parquet"
    notebook: "notebooks/population/Discretize population.ipynb"

rule discretize_passengers:
    input:
        population="results/madrid/population/weighted_population.parquet",
        spatial="results/madrid/census/spatial.parquet"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 2,
        only_passengers=True
    output: "results/madrid/population/discretized_passengers_seed{seed}.parquet"
    notebook: "notebooks/population/Discretize population.ipynb"

# Spatial localization of persons

rule localize_passengers:
    input:
        passengers="results/madrid/population/discretized_passengers_seed{seed}.parquet",
        locations="results/madrid/osm/locations.parquet"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 3,
        zone_attribute="municipality_id"
    output: "results/madrid/population/localized_passengers_seed{seed}.parquet"
    notebook: "notebooks/population/Localize population (location-based).ipynb"

# Enrichment of the passenger population

rule enrich_group_size:
    input:
        target="results/madrid/population/localized_passengers_seed{seed}.parquet",
        distribution="results/madrid/airport/group_sizes.parquet"
    params:
        attributes=["group_size"],
        seed=lambda wildcards: int(wildcards["seed"]) + 4
    output: "results/madrid/population/passengers_with_group_size_seed{seed}.parquet"
    notebook: "notebooks/population/Perform enrichment.ipynb"

rule enrich_passenger_profile:
    input:
        target="results/madrid/population/passengers_with_group_size_seed{seed}.parquet",
        distribution="results/madrid/airport/passenger_profiles.parquet"
    params:
        attributes=["passenger_profile"],
        seed=lambda wildcards: int(wildcards["seed"]) + 5
    output: "results/madrid/population/passengers_with_profile_seed{seed}.parquet"
    notebook: "notebooks/population/Perform enrichment.ipynb"

rule enrich_departure_hour:
    input:
        target="results/madrid/population/passengers_with_profile_seed{seed}.parquet",
        distribution="results/madrid/airport/departure_hours.parquet"
    params:
        attributes=["departure_hour"],
        seed=lambda wildcards: int(wildcards["seed"]) + 6
    output: "results/madrid/population/passengers_with_departure_hour_seed{seed}.parquet"
    notebook: "notebooks/population/Perform enrichment.ipynb"

# Generate trips with origins, destinations, and departure time

rule generate_trips:
    input:
        passengers="results/madrid/population/passengers_with_departure_hour_seed{seed}.parquet",
        airports="resources/madrid/airport/location.gpkg"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 7
    output: "results/madrid/trips/passenger_trips_seed{seed}.{ext}"
    notebook: "notebooks/trips/Generate trips.ipynb"

# Default rule to generate population and passenger trips

rule all:
    input:
        "results/madrid/population/discretized_population_seed1000.parquet",
        "results/madrid/trips/passenger_trips_seed1000.gpkg"
    default_target: True
