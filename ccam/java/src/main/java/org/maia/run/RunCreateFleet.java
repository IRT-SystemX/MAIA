package org.maia.run;

import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedList;
import java.util.List;

import org.matsim.api.core.v01.Coord;
import org.matsim.api.core.v01.Id;
import org.matsim.api.core.v01.Scenario;
import org.matsim.api.core.v01.network.Link;
import org.matsim.api.core.v01.network.Network;
import org.matsim.api.core.v01.population.Activity;
import org.matsim.api.core.v01.population.Person;
import org.matsim.contrib.dvrp.fleet.DvrpVehicle;
import org.matsim.contrib.dvrp.fleet.DvrpVehicleSpecification;
import org.matsim.contrib.dvrp.fleet.FleetWriter;
import org.matsim.contrib.dvrp.fleet.ImmutableDvrpVehicleSpecification;
import org.matsim.contrib.dvrp.load.DvrpLoadType;
import org.matsim.contrib.dvrp.load.IntegerLoadType;
import org.matsim.core.config.CommandLine;
import org.matsim.core.config.Config;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.network.NetworkUtils;
import org.matsim.core.network.algorithms.TransportModeNetworkFilter;
import org.matsim.core.network.io.MatsimNetworkReader;
import org.matsim.core.population.io.PopulationReader;
import org.matsim.core.scenario.ScenarioUtils;

import scala.util.Random;

public class RunCreateFleet {
    static public void main(String[] args) throws org.matsim.core.config.CommandLine.ConfigurationException {
        CommandLine cmd = new CommandLine.Builder(args) //
                .requireOptions("demand-path", "vehicles", "output-path", "network-path", "capacity") //
                .build();

        // get command line options
        String networkPath = cmd.getOptionStrict("network-path");
        String demandPath = cmd.getOptionStrict("demand-path");
        String outputPath = cmd.getOptionStrict("output-path");

        int vehicles = Integer.parseInt(cmd.getOptionStrict("vehicles"));
        int capacity = Integer.parseInt(cmd.getOptionStrict("capacity"));

        // load data
        Config config = ConfigUtils.createConfig();
        Scenario scenario = ScenarioUtils.createScenario(config);

        new MatsimNetworkReader(scenario.getNetwork()).readFile(networkPath);
        new PopulationReader(scenario).readFile(demandPath);

        // find earliest departures
        List<Activity> departureActivities = new LinkedList<>();

        for (Person person : scenario.getPopulation().getPersons().values()) {
            departureActivities.add((Activity) person.getSelectedPlan().getPlanElements().get(0));
        }

        Collections.sort(departureActivities, Comparator.comparing(a -> a.getEndTime().seconds()));

        // clean network
        Network network = NetworkUtils.createNetwork();
        new TransportModeNetworkFilter(scenario.getNetwork()).filter(network, Collections.singleton("car"));

        // obtain early departure links
        List<Link> startLinks = new LinkedList<>();

        for (Activity departure : departureActivities) {
            Coord coordinate = departure.getCoord();
            Link link = NetworkUtils.getNearestLink(network, coordinate);
            startLinks.add(link);
        }

        // if not enough, sample randomly
        List<Link> candidates = new LinkedList<>(network.getLinks().values());
        Collections.sort(candidates, Comparator.comparing(l -> l.getId().toString()));
        Random random = new Random(0);

        while (startLinks.size() < vehicles) {
            startLinks.add(candidates.get(random.nextInt(candidates.size())));
        }

        // create fleet
        List<DvrpVehicleSpecification> fleet = new LinkedList<>();

        for (int k = 0; k < vehicles; k++) {
            Link startLink = startLinks.get(k);

            fleet.add(ImmutableDvrpVehicleSpecification.newBuilder() //
                    .id(Id.create("drt:" + k, DvrpVehicle.class)) //
                    .startLinkId(startLink.getId()) //
                    .capacity(capacity) //
                    .serviceBeginTime(0.0)
                    .serviceEndTime(30.0 * 3600.0)
                    .build());
        }

        DvrpLoadType loadType = new IntegerLoadType("passengers");
        new FleetWriter(fleet.stream(), loadType).write(outputPath);
    }
}
