package org.maia.disruption;

import java.util.Map;

import org.matsim.api.core.v01.network.Link;
import org.matsim.core.mobsim.qsim.qnetsimengine.QVehicle;
import org.matsim.core.mobsim.qsim.qnetsimengine.linkspeedcalculator.LinkSpeedCalculator;

public final class DisruptionLinkSpeedCalculator implements LinkSpeedCalculator {

    @Override
    public double getMaximumVelocity(QVehicle vehicle, Link link, double time) {
        double speed = link.getFreespeed(time);
        Map<String, Object> attributeMap = link.getAttributes().getAsMap();
        for (Object key : attributeMap.keySet()) {
            String[] stringKey = key.toString().split("_");
            if (stringKey[0].equals("congestion")) {
                if ((Double.parseDouble(link.getAttributes()
                        .getAttribute(String.format("start_congestion_%s", stringKey[1])).toString()) <= time)
                        && (Double.parseDouble(link.getAttributes()
                                .getAttribute(String.format("end_congestion_%s", stringKey[1])).toString()) >= time)) {
                    double congestion_factor = (double) attributeMap.get(key);
                    speed = speed * congestion_factor;
                }
            }
        }
        return Math.min(vehicle.getMaximumVelocity(), speed);
    }
}
