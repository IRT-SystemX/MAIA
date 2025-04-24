package org.maia.disruption;

import java.util.Comparator;
import java.util.Map;
import java.util.PriorityQueue;

import org.matsim.api.core.v01.Id;
import org.matsim.api.core.v01.IdMap;
import org.matsim.api.core.v01.network.Link;
import org.matsim.api.core.v01.network.Network;
import org.matsim.api.core.v01.population.Person;
import org.matsim.core.mobsim.framework.events.MobsimBeforeSimStepEvent;
import org.matsim.core.mobsim.framework.listeners.MobsimBeforeSimStepListener;
import org.matsim.core.router.util.TravelTime;
import org.matsim.core.trafficmonitoring.FreeSpeedTravelTime;
import org.matsim.vehicles.Vehicle;

public class DisruptionTravelTime implements TravelTime, MobsimBeforeSimStepListener {
	private final TravelTime delegate = new FreeSpeedTravelTime();

	private IdMap<Link, Double> congestionFactors = new IdMap<>(Link.class);

	private record FactorChange(double time, Id<Link> linkId, double factor) {
	}

	private PriorityQueue<FactorChange> queue = new PriorityQueue<>( //
			Comparator.comparing(c -> c.time()));

	public DisruptionTravelTime(Network network) {
		for (Link link : network.getLinks().values()) {
			Map<String, Object> attributeMap = link.getAttributes().getAsMap();
			for (Object key : attributeMap.keySet()) {
				String[] stringKey = key.toString().split("_");
				if (stringKey[0].equals("congestion")) {
					if (link.getAttributes()
							.getAttribute(String.format("comunication_congestion_%s", stringKey[1])) != null) {
						double startTime = Double.parseDouble(link.getAttributes()
								.getAttribute(String.format("start_congestion_%s", stringKey[1])).toString());
						double endTime = Double.parseDouble(link.getAttributes()
								.getAttribute(String.format("end_congestion_%s", stringKey[1])).toString());
						double communicationDelay = Double.parseDouble(link.getAttributes()
								.getAttribute(String.format("comunication_congestion_%s", stringKey[1])).toString());
						double congestion_factor = (double) attributeMap.get(key);

						queue.add(new FactorChange(startTime + communicationDelay, link.getId(), congestion_factor));

						endTime = Math.max(endTime, startTime + communicationDelay + 1.0);
						queue.add(new FactorChange(endTime, link.getId(), 1.0));
					}
				}
			}
		}
	}

	@Override
	public void notifyMobsimBeforeSimStep(@SuppressWarnings("rawtypes") MobsimBeforeSimStepEvent e) {
		while (!queue.isEmpty() && queue.peek().time <= e.getSimulationTime()) {
			FactorChange change = queue.poll();
			congestionFactors.put(change.linkId, change.factor);
		}
	}

	@Override
	public double getLinkTravelTime(Link link, double time, Person person, Vehicle vehicle) {
		return congestionFactors.getOrDefault(link.getId(), 1.0)
				* delegate.getLinkTravelTime(link, time, person, vehicle);
	}
}
