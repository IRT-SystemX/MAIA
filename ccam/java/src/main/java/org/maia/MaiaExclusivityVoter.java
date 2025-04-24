package org.maia;

import org.matsim.api.core.v01.Id;
import org.matsim.api.core.v01.IdSet;
import org.matsim.api.core.v01.population.Person;
import org.matsim.api.core.v01.population.Population;
import org.matsim.contrib.drt.extension.insertion.constraints.ExclusivityConstraint.ExclusivityVoter;
import org.matsim.contrib.drt.passenger.DrtRequest;

public class MaiaExclusivityVoter implements ExclusivityVoter {
    private final IdSet<Person> exclusiveIds = new IdSet<>(Person.class);

    public MaiaExclusivityVoter(Population population) {
        for (Person person : population.getPersons().values()) {
            Boolean isPoolable = (Boolean) person.getAttributes().getAttribute("isPoolable");

            if (!isPoolable) {
                exclusiveIds.add(person.getId());
            }
        }
    }

    @Override
    public boolean isExclusive(DrtRequest request) {
        for (Id<Person> passengerId : request.getPassengerIds()) {
            if (exclusiveIds.contains(passengerId)) {
                return true;
            }
        }

        return false;
    }
}
