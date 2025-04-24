package org.maia;

import org.matsim.api.core.v01.IdMap;
import org.matsim.api.core.v01.population.Person;
import org.matsim.api.core.v01.population.Population;
import org.matsim.contrib.drt.passenger.DrtRequest;
import org.matsim.contrib.drt.stops.PassengerStopDurationProvider;
import org.matsim.contrib.dvrp.fleet.DvrpVehicle;

import com.google.inject.Inject;

public class MaiaStopTimeProvider implements PassengerStopDurationProvider {
    private final IdMap<Person, Double> interactionTimes = new IdMap<>(Person.class);

    @Inject
    public MaiaStopTimeProvider(Population population) {
        for (Person person : population.getPersons().values()) {
            double interactionTime = (Double) person.getAttributes().getAttribute("interactionTime");
            interactionTimes.put(person.getId(), interactionTime);
        }
    }

    @Override
    public double calcPickupDuration(DvrpVehicle dvrpVehicle, DrtRequest drtRequest) {
        return drtRequest.getPassengerIds().stream()
                .mapToDouble(interactionTimes::get)
                .max().orElseThrow();
    }

    @Override
    public double calcDropoffDuration(DvrpVehicle dvrpVehicle, DrtRequest drtRequest) {
        return calcPickupDuration(dvrpVehicle, drtRequest);
    }
}
