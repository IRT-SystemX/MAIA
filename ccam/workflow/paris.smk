## MAIA-CCAM pipeline for Paris

# Settings
areas = ["main", "main+south"]
seeds = [1000]
fleet_sizes = [50, 100, 200]
capacity = 14
profiles = ["economy", "business"] # add "all" for a joint simulation

threads = 12

# Imports
module java:
    snakefile: "java.smk"
    config: config

use rule prepare_maia from java
use rule build_maia from java

# Prepare network by cutting OSM data and extracting road data
rule prepare_network:
    input:
        osm="resources/paris/osm/ile-de-france-latest.osm.pbf",
        areas="resources/paris/spatial.gpkg"
    params: area="network"
    output: "results/paris/networks/network.osm.pbf"
    notebook: "notebooks/Prepare network.ipynb"

# Convert network to MATSim format
rule convert_network:
    input: 
        osm="results/paris/networks/network.osm.pbf",
        maia="results/maia.jar"
    params: 
        memory="12g", crs="EPSG:2154"
    output: "results/paris/networks/network.xml.gz"
    script: "scripts/convert_network.sh"

# Construct opreating areas
rule construct_operating_areas:
    input: "resources/paris/spatial.gpkg"
    output: "results/paris/combined_areas.gpkg"
    notebook: "notebooks/Combine areas.ipynb"

# Filter the demand by operating area
rule filter_demand:
    input:
        demand="../demand/results/paris/trips/passenger_trips_seed{seed}.gpkg",
        areas="results/paris/combined_areas.gpkg"
    params: area="{area}"
    output: "results/paris/demand/filtered/demand_{area}_{seed}.gpkg"
    notebook: "notebooks/Filter demand.ipynb"

# Enrich the demand
rule enrich_demand:
    input:
        demand="results/paris/demand/filtered/demand_{area}_{seed}.gpkg",
        enrichment="resources/paris/enrichment.yml"
    params: seed="{seed}"
    output: "results/paris/demand/enriched/demand_{area}_{seed}.gpkg"
    notebook: "notebooks/Enrich demand.ipynb"

# Extract demand for a specific profile
rule extract_profile:
    input: "results/paris/demand/enriched/demand_{area}_{seed}.gpkg"
    params: profile="{profile}"
    output: "results/paris/demand/profile/demand_{area}_{profile}_{seed}.gpkg"
    notebook: "notebooks/Extract profile.ipynb"

# Convert demand to MATSim format
rule create_matsim_demand:
    input: 
        maia="results/maia.jar",
        demand="results/paris/demand/profile/demand_{area}_{profile}_{seed}.gpkg"
    params: memory="12g"
    output: "results/paris/demand/matsim/demand_{area}_{profile}_{seed}.xml.gz"
    script: "scripts/create_demand.sh"

# Create MATSim fleet
rule create_matsim_fleet:
    input: 
        maia="results/maia.jar",
        demand="results/paris/demand/matsim/demand_{area}_{profile}_{seed}.xml.gz",
        network="results/paris/networks/network.xml.gz"
    params: memory="12g", vehicles="{vehicles}", capacity="{capacity}"
    output: "results/paris/fleet/fleet_{area}_{profile}_{seed}_{vehicles}_{capacity}.xml.gz"
    script: "scripts/create_fleet.sh"

# Run create travel time matrix
rule run_create_travel_time_matrix:
    input:
        maia="results/maia.jar",
        network="results/paris/networks/network.xml.gz"
    params: memory="12g", cellsize="400", threads=threads
    output: "results/paris/travel_time_matrix/{area}.bin.gz"
    script: "scripts/create_travel_time_matrix.sh"

# Run MATSim simulation
rule run_matsim_simulation:
    input:
        maia="results/maia.jar",
        demand="results/paris/demand/matsim/demand_{area}_{profile}_{seed}.xml.gz",
        network="results/paris/networks/network.xml.gz",
        travel_time_matrix="results/paris/travel_time_matrix/{area}.bin.gz",
        fleet="results/paris/fleet/fleet_{area}_{profile}_{seed}_{vehicles}_{capacity}.xml.gz"
    params: memory="12g", cellsize="400", threads=threads
    output: 
        output=directory("results/paris/matsim/output_{area}_{profile}_{seed}_{vehicles}_{capacity}"),
    script: "scripts/run_simulation.sh"

# Prepare analysis
rule prepare_analysis:
    input:
        demand="results/paris/demand/profile/demand_{area}_{profile}_{seed}.gpkg",
        simulation="results/paris/matsim/output_{area}_{profile}_{seed}_{vehicles}_{capacity}"
    output: "results/paris/analysis/{area}_{profile}_{seed}_{vehicles}_{capacity}.pickle"
    notebook: "notebooks/Prepare analysis.ipynb"

# Run all cases
rule all:
    input: 
        expand(
        "results/paris/analysis/{area}_{profile}_{seed}_{fleet_size}_{capacity}.pickle",
        area = areas, profile = profiles, seed = seeds, fleet_size = fleet_sizes, capacity = [capacity])
