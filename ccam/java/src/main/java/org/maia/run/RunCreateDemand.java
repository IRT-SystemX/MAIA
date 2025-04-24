package org.maia.run;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;

import org.geotools.api.data.SimpleFeatureReader;
import org.geotools.api.feature.simple.SimpleFeature;
import org.geotools.geopkg.FeatureEntry;
import org.geotools.geopkg.GeoPackage;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.Point;
import org.matsim.api.core.v01.Coord;
import org.matsim.api.core.v01.Id;
import org.matsim.api.core.v01.Scenario;
import org.matsim.api.core.v01.population.Activity;
import org.matsim.api.core.v01.population.Leg;
import org.matsim.api.core.v01.population.Person;
import org.matsim.api.core.v01.population.Plan;
import org.matsim.api.core.v01.population.Population;
import org.matsim.api.core.v01.population.PopulationFactory;
import org.matsim.contrib.drt.prebooking.logic.AttributeBasedPrebookingLogic;
import org.matsim.core.config.CommandLine;
import org.matsim.core.config.Config;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.population.io.PopulationWriter;
import org.matsim.core.scenario.ScenarioUtils;

import com.google.common.base.Preconditions;

public class RunCreateDemand {
    static public void main(String[] args)
            throws org.matsim.core.config.CommandLine.ConfigurationException, MalformedURLException, IOException {
        CommandLine cmd = new CommandLine.Builder(args) //
                .requireOptions("demand-path", "output-path") //
                .allowOptions() //
                .build();

        // get command line options
        String demandPath = cmd.getOptionStrict("demand-path");
        String outputPath = cmd.getOptionStrict("output-path");

        System.out.println(new File(demandPath).toURI().toURL());

        try (GeoPackage source = new GeoPackage(new File(demandPath))) {
            source.init();

            // set up population
            Config config = ConfigUtils.createConfig();
            Scenario scenario = ScenarioUtils.createScenario(config);

            Population population = scenario.getPopulation();
            PopulationFactory factory = population.getFactory();

            for (FeatureEntry featureEntry : source.features()) {
                try (SimpleFeatureReader reader = source.reader(featureEntry, null, null)) {
                    while (reader.hasNext()) {
                        // convert to MATSim persons / plans / trips
                        SimpleFeature feature = reader.next();
                        LineString geometry = (LineString) feature.getDefaultGeometry();

                        String requestId = (String) feature.getAttribute("request_id");
                        Preconditions.checkNotNull(requestId);

                        Long groupSize = (Long) feature.getAttribute("group_size");
                        Preconditions.checkNotNull(groupSize);
                        groupSize = groupSize == null ? 1 : groupSize;

                        for (int k = 0; k < groupSize; k++) {
                            Person person = factory.createPerson(Id.createPersonId("request:" + requestId + ":" + k));
                            population.addPerson(person);

                            // group
                            person.getAttributes().putAttribute("groupId", "group:" + requestId);

                            Plan plan = factory.createPlan();
                            person.addPlan(plan);

                            double departureTime = (double) feature.getAttribute("departure_time");

                            Point originPoint = geometry.getStartPoint();
                            Point destinationPoint = geometry.getEndPoint();

                            Coord originCoord = new Coord(originPoint.getX(), originPoint.getY());
                            Coord destinationCoord = new Coord(destinationPoint.getX(), destinationPoint.getY());

                            Activity originActivity = factory.createActivityFromCoord("generic", originCoord);
                            originActivity.setEndTime(departureTime);
                            plan.addActivity(originActivity);

                            Leg leg = factory.createLeg("drt");
                            plan.addLeg(leg);

                            Activity destinationActivity = factory.createActivityFromCoord("generic",
                                    destinationCoord);
                            plan.addActivity(destinationActivity);

                            // attributes
                            Double interactionTime = (Double) feature.getAttribute("interaction_time");
                            Preconditions.checkNotNull(interactionTime);
                            person.getAttributes().putAttribute("interactionTime", interactionTime);

                            Double maxiumWaitTime = (Double) feature.getAttribute("maximum_wait_time");
                            Preconditions.checkNotNull(maxiumWaitTime);
                            person.getAttributes().putAttribute("maximumWaitTime", maxiumWaitTime);

                            Double detourFactor = (Double) feature.getAttribute("detour_factor");
                            Preconditions.checkNotNull(detourFactor);
                            person.getAttributes().putAttribute("detourFactor", detourFactor);

                            Boolean isPoolable = (Boolean) feature.getAttribute("is_poolable");
                            Preconditions.checkNotNull(isPoolable);
                            person.getAttributes().putAttribute("isPoolable", isPoolable);

                            Double latestArrivalTime = (Double) feature.getAttribute("latest_arrival_time");
                            if (latestArrivalTime != null) {
                                person.getAttributes().putAttribute("latestArrivalTime", latestArrivalTime);
                            }

                            // prebooking
                            Double prebookingTime = (Double) feature.getAttribute("prebooking_time");
                            if (prebookingTime != null && prebookingTime > 0.0) {
                                double submissionTime = Math.max(0.0, departureTime - prebookingTime);

                                AttributeBasedPrebookingLogic.setSubmissionTime("drt", originActivity, submissionTime);

                                Double delay = (Double) feature.getAttribute("delay");
                                if (delay != null) {
                                    originActivity.setEndTime(departureTime + delay);
                                    AttributeBasedPrebookingLogic.setPlannedDepartureTime("drt", originActivity,
                                            departureTime);
                                }
                            }
                        }
                    }
                }
            }

            // output
            new PopulationWriter(population).write(outputPath);
        }
    }
}
