package org.maia.disruption;

import org.matsim.core.mobsim.qsim.AbstractQSimModule;

public class DisruptionQSimModule extends AbstractQSimModule {
    @Override
    protected void configureQSim() {
        addLinkSpeedCalculatorBinding().to(DisruptionLinkSpeedCalculator.class).asEagerSingleton();
    }
}