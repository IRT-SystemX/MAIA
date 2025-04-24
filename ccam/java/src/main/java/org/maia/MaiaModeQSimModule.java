package org.maia;

import java.util.Optional;

import org.matsim.api.core.v01.Id;
import org.matsim.api.core.v01.IdMap;
import org.matsim.api.core.v01.population.Person;
import org.matsim.api.core.v01.population.Population;
import org.matsim.contrib.dvrp.passenger.PassengerGroupIdentifier;
import org.matsim.contrib.dvrp.passenger.PassengerGroupIdentifier.PassengerGroup;
import org.matsim.contrib.dvrp.run.AbstractDvrpModeQSimModule;

import com.google.common.base.Preconditions;
import com.google.inject.Singleton;

public class MaiaModeQSimModule extends AbstractDvrpModeQSimModule {
    public MaiaModeQSimModule(String mode) {
        super(mode);
    }

    @Override
    public void configureQSim() {
        bindModal(PassengerGroupIdentifier.class).toProvider(modalProvider(getter -> {
            IdMap<Person, Id<PassengerGroup>> mapping = new IdMap<>(Person.class);

            for (Person person : getter.get(Population.class).getPersons().values()) {
                String groupId = (String) person.getAttributes().getAttribute("groupId");
                Preconditions.checkNotNull(groupId);
                mapping.put(person.getId(), Id.create(groupId, PassengerGroup.class));
            }

            return agent -> Optional.of(mapping.get(agent.getId()));
        })).in(Singleton.class);

        bindModal(MaiaExclusivityVoter.class).toProvider(modalProvider(getter -> {
            Population population = getter.get(Population.class);
            return new MaiaExclusivityVoter(population);
        })).in(Singleton.class);
    }
}
