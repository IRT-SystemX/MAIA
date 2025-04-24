package org.maia;

import org.matsim.contrib.drt.routing.DrtRouteConstraintsCalculator;
import org.matsim.contrib.drt.run.DrtConfigGroup;
import org.matsim.contrib.drt.stops.PassengerStopDurationProvider;
import org.matsim.contrib.dvrp.run.AbstractDvrpModeModule;

import com.google.inject.Singleton;

public class MaiaModeModule extends AbstractDvrpModeModule {
	public MaiaModeModule(DrtConfigGroup modeConfig) {
		super(modeConfig.getMode());
	}

	@Override
	public void install() {
		bindModal(DrtRouteConstraintsCalculator.class).to(MaiaRouteConstraintsCalculator.class).in(Singleton.class);
		bindModal(PassengerStopDurationProvider.class).to(MaiaStopTimeProvider.class).in(Singleton.class);
	}
}