### MAIA-Engine BRU (Extended)

date = "max"

module base:
    snakefile: "../../../demand/workflow/brussels.smk"
    config: config

use rule prepare_municipality_data from base
use rule prepare_sector_data from base
use rule prepare_spatial_data from base
use rule extract_buildings from base
use rule initialize_population from base
use rule discretize_population from base
use rule discretize_passengers from base
use rule localize_passengers from base
use rule generate_trips from base

# Prepare additional open data

rule prepare_provinces:
    input: "results/brussels/census/spatial.parquet"
    output: "results/brussels/census/provinces.parquet"
    notebook: "notebooks/demand/Prepare provinces.ipynb"

# Process proprietary airport data

rule prepare_daily_total:
    input: 
        departures="resources/brussels/airport/2023.Departure.aggregate.xlsx",
        arrivals="resources/brussels/airport/2023.Arrival.aggregate.xlsx",
    params:
        date=date
    output: "results/brussels/airport/daily_totals.parquet"
    notebook: "notebooks/demand/airport/Prepare daily total.ipynb"

rule prepare_group_size:
    input: "resources/brussels/airport/group_size_surveys_TML.csv"
    output: "results/brussels/airport/group_sizes.parquet"
    notebook: "notebooks/demand/airport/Prepare group size.ipynb"

rule prepare_passenger_survey:
    input: "resources/brussels/airport/resp_by_mun_age_sex_TML.csv"
    output: "results/brussels/airport/survey.parquet"
    notebook: "notebooks/demand/airport/Prepare passenger data.ipynb"

rule prepare_luggage:
    input: "resources/brussels/airport/luggage_distribution_per_province_cabin_class.xlsx"
    output: "results/brussels/airport/luggage.parquet"
    notebook: "notebooks/demand/airport/Prepare luggage data.ipynb"

rule prepare_purpose:
    input: "resources/brussels/airport/trip_purpuse_distribution_per_province_cabin_class.xlsx"
    output: "results/brussels/airport/purpose.parquet"
    notebook: "notebooks/demand/airport/Prepare purpose data.ipynb"

rule prepare_frequent_flyer:
    input: "resources/brussels/airport/trip_frequency_distribution_per_province_cabin_class.xlsx"
    output: "results/brussels/airport/frequent_flyer.parquet"
    notebook: "notebooks/demand/airport/Prepare frequent flyer data.ipynb"

rule prepare_cabin_class:
    input: "results/brussels/airport/purpose.parquet"
    output: "results/brussels/airport/cabin_class.parquet"
    notebook: "notebooks/demand/airport/Prepare cabin class.ipynb"

rule prepare_departure_hours:
    input: "resources/brussels/airport/Aggregated_Departure_Times_by_Cabin_Class.csv"
    output: "results/brussels/airport/departure_hours.parquet"
    notebook: "notebooks/demand/airport/Prepare departure hour.ipynb"

rule prepare_post_codes:
    input: "resources/brussels/Postcode.zip"
    output: "results/brussels/post_codes.parquet"
    notebook: "notebooks/demand/Prepare post codes.ipynb"

rule prepare_parking:
    input: "resources/brussels/airport/Grouped_Parking_Data.csv"
    output: "results/brussels/airport/parking.parquet"
    notebook: "notebooks/demand/airport/Prepare parking data.ipynb"

# Prepare extended fitting marginals

rule prepare_marginals:
    input:
        municipalities="results/brussels/census/municipalities.parquet",
        sectors="results/brussels/census/sectors.parquet",
        survey="results/brussels/airport/survey.parquet",
        daily="results/brussels/airport/daily_totals.parquet",
        group_sizes="results/brussels/airport/group_sizes.parquet",
        locations="results/brussels/osm/locations.parquet"
    output:
        municipalities="results/brussels/marginals/municipalities.parquet",
        sectors="results/brussels/marginals/sectors.parquet",
        passengers="results/brussels/marginals/passengers.parquet",
        missing_locations="results/brussels/marginals/missing_locations.parquet"
    notebook: "notebooks/demand/Prepare marginals.ipynb"

# Perform Iterative Proprtional Fitting

use rule iterative_proportional_fitting from base as extended_iterative_proportional_fitting with:
    input:
        seed="results/brussels/population/initial_population.parquet",
        marginal_municipalities="results/brussels/marginals/municipalities.parquet",
        marginal_sectors="results/brussels/marginals/sectors.parquet",
        marginal_passengers="results/brussels/marginals/passengers.parquet",
        marginal_missing_locations="results/brussels/marginals/missing_locations.parquet"

# Enrichment of the passenger population

rule enrich_group_size:
    input:
        target="results/brussels/population/localized_passengers_seed{seed}.parquet",
        distribution="results/brussels/airport/group_sizes.parquet"
    params:
        attributes=["group_size"],
        seed=lambda wildcards: int(wildcards["seed"]) + 4
    output: "results/brussels/population/passengers_with_group_size_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Perform enrichment.ipynb"

rule enrich_province:
    input:
        target="results/brussels/population/passengers_with_group_size_seed{seed}.parquet",
        distribution="results/brussels/census/provinces.parquet"
    params:
        match=["municipality_id"],
        attributes=["province"],
        seed=lambda wildcards: int(wildcards["seed"]) +5 
    output: "results/brussels/population/passengers_with_province_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Perform enrichment.ipynb"

rule enrich_cabin_class:
    input:
        target="results/brussels/population/passengers_with_province_seed{seed}.parquet",
        distribution="results/brussels/airport/cabin_class.parquet"
    params:
        match=["province"],
        attributes=["cabin_class"],
        seed=lambda wildcards: int(wildcards["seed"]) + 6
    output: "results/brussels/population/passengers_with_cabin_class_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Perform enrichment.ipynb"

rule enrich_departure_hour:
    input:
        target="results/brussels/population/passengers_with_cabin_class_seed{seed}.parquet",
        distribution="results/brussels/airport/departure_hours.parquet"
    params:
        match=["cabin_class"],
        attributes=["departure_hour"],
        seed=lambda wildcards: int(wildcards["seed"]) + 7
    output: "results/brussels/population/passengers_with_departure_hour_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Perform enrichment.ipynb"

rule enrich_access:
    input:
        target="results/brussels/population/passengers_with_departure_hour_seed{seed}.parquet",
        distribution="results/brussels/airport/daily_totals.parquet"
    params:
        attributes=["is_access"],
        seed=lambda wildcards: int(wildcards["seed"]) + 8
    output: "results/brussels/population/passengers_with_access_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Perform enrichment.ipynb"

rule enrich_purpose:
    input:
        target="results/brussels/population/passengers_with_access_seed{seed}.parquet",
        distribution="results/brussels/airport/purpose.parquet"
    params:
        match=["cabin_class", "province"],
        attributes=["purpose"],
        seed=lambda wildcards: int(wildcards["seed"]) + 9
    output: "results/brussels/population/passengers_with_purpose_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Perform enrichment.ipynb"

rule enrich_frequent_flyer:
    input:
        target="results/brussels/population/passengers_with_purpose_seed{seed}.parquet",
        distribution="results/brussels/airport/frequent_flyer.parquet"
    params:
        match=["cabin_class", "province"],
        attributes=["frequent_flyer"],
        seed=lambda wildcards: int(wildcards["seed"]) + 10
    output: "results/brussels/population/passengers_with_frequent_flyer_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Perform enrichment.ipynb"

rule enrich_luggage:
    input:
        target="results/brussels/population/passengers_with_frequent_flyer_seed{seed}.parquet",
        distribution="results/brussels/airport/luggage.parquet"
    params:
        match=["cabin_class", "province"],
        attributes=["luggage_size"],
        seed=lambda wildcards: int(wildcards["seed"]) + 11
    output: "results/brussels/population/passengers_with_luggage_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Perform enrichment.ipynb"

rule enrich_parking:
    input:
        target="results/brussels/population/passengers_with_luggage_seed{seed}.parquet",
        distribution="results/brussels/airport/parking.parquet"
    params:
        match=["cabin_class", "province"],
        attributes=["use_parking"],
        seed=lambda wildcards: int(wildcards["seed"]) + 12
    output: "results/brussels/population/passengers_with_parking_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Perform enrichment.ipynb"

rule enrich_postcode:
    input: 
        zones="results/brussels/post_codes.parquet",
        target="results/brussels/population/passengers_with_parking_seed{seed}.parquet"
    params:
        attributes=["postcode"]
    output: "results/brussels/population/passengers_with_postcode_seed{seed}.parquet"
    notebook: "../../../demand/workflow/notebooks/population/Spatial imputation.ipynb"

rule finish_enrichment:
    input: "results/brussels/population/passengers_with_postcode_seed{seed}.parquet"
    output: "results/brussels/population/passengers_enriched_seed{seed}.parquet"
    shell: "cp {input[0]} {output[0]}"

# Convert output to Excel

rule generate_excel:
    input: "results/brussels/trips/passenger_trips_seed{seed}.gpkg"
    params:
        seed=lambda wildcards: int(wildcards["seed"]) + 14
    output: "results/brussels/trips/passenger_trips_seed{seed}.xlsx"
    notebook: "notebooks/demand/Convert Excel.ipynb"

# Default rule to generate population and passenger trips

rule all:
    input:
        "results/brussels/population/discretized_population_seed1000.parquet",
        "results/brussels/trips/passenger_trips_seed1000.gpkg",
        "results/brussels/trips/passenger_trips_seed1000.xlsx"
    default_target: True
