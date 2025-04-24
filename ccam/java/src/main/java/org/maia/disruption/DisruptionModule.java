
package org.maia.disruption;

import org.matsim.api.core.v01.network.Network;
import org.matsim.contrib.dvrp.run.AbstractDvrpModeModule;
import org.matsim.core.router.util.TravelTime;

public class DisruptionModule extends AbstractDvrpModeModule {
  public DisruptionModule(String mode) {
    super(mode);
  }

  @Override
  public void install() {
    bindModal(DisruptionTravelTime.class).toProvider(modalProvider(getter -> {
      Network network = getter.getModal(Network.class);
      return new DisruptionTravelTime(network);
    }));

    addMobsimListenerBinding().to(modalKey(DisruptionTravelTime.class));
    bindModal(TravelTime.class).to(modalKey(DisruptionTravelTime.class));
  }
}
