### MAIA CCAM build pipeline
# This pipeline creates a JAR based on the java code.

# TODO: Use a conda-installed java and maven environment

rule prepare_maia:
    input: directory("java")
    output: directory("results/build_maia")
    shell: "cp -r {input} {output}"

rule build_maia:
    input: directory("results/build_maia")
    output: "results/maia.jar"
    shell: "cd {input} && mvn clean package -Pstandalone && cp target/maia-1.0-SNAPSHOT.jar ../maia.jar"

rule clone_eqasim:
    output: directory("results/eqasim-java")
    shell: "git clone https://github.com/eqasim-org/eqasim-java.git {output} && cd {output} && git checkout 90a737d"

rule build_eqasim:
    input: directory("results/eqasim-java")
    output: "results/eqasim_idf.jar", "results/eqasim_server.jar"
    shell: "cd {input} && mvn clean package -Pstandalone -DskipTests=true --projects server,ile_de_france --also-make && cp ile_de_france/target/ile_de_france-1.5.0.jar ../eqasim_idf.jar && cp server/target/server-1.5.0.jar ../eqasim_server.jar"
