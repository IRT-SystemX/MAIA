package org.maia;

import org.matsim.api.core.v01.network.Link;
import org.matsim.api.core.v01.population.Person;
import org.matsim.contrib.drt.optimizer.constraints.DrtRouteConstraints;
import org.matsim.contrib.drt.routing.DrtRouteConstraintsCalculator;
import org.matsim.utils.objectattributes.attributable.Attributes;

public class MaiaRouteConstraintsCalculator implements DrtRouteConstraintsCalculator {
    @Override
    public DrtRouteConstraints calculateRouteConstraints(double departureTime, Link accessActLink, Link egressActLink,
            Person person, Attributes tripAttributes, double unsharedRideTime, double unsharedDistance) {
        double detourFactor = (Double) person.getAttributes().getAttribute("detourFactor");
        double maximumRideTime = detourFactor * unsharedRideTime;

        double maximumWaitTime = (Double) person.getAttributes().getAttribute("maximumWaitTime");
        double maximumTravelTime = detourFactor * unsharedRideTime + maximumWaitTime;

        Double latestArrivalTime = (Double) person.getAttributes().getAttribute("latestArrivalTime");
        if (latestArrivalTime != null) {
            maximumTravelTime = latestArrivalTime - departureTime;
        }

        return new DrtRouteConstraints(maximumTravelTime, maximumRideTime, maximumWaitTime);
    }
}
