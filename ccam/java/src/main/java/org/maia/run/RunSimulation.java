package org.maia.run;

import java.io.IOException;

import org.maia.MaiaExclusivityVoter;
import org.maia.MaiaModeModule;
import org.maia.MaiaModeQSimModule;
import org.matsim.api.core.v01.Scenario;
import org.matsim.contrib.common.zones.systems.grid.square.SquareGridZoneSystemParams;
import org.matsim.contrib.drt.extension.insertion.DrtInsertionModule;
import org.matsim.contrib.drt.optimizer.constraints.DefaultDrtOptimizationConstraintsSet;
import org.matsim.contrib.drt.optimizer.insertion.extensive.ExtensiveInsertionSearchParams;
import org.matsim.contrib.drt.prebooking.PrebookingParams;
import org.matsim.contrib.drt.prebooking.logic.AttributeBasedPrebookingLogic;
import org.matsim.contrib.drt.routing.DrtRoute;
import org.matsim.contrib.drt.routing.DrtRouteFactory;
import org.matsim.contrib.drt.run.DrtConfigGroup;
import org.matsim.contrib.drt.run.DrtConfigs;
import org.matsim.contrib.drt.run.MultiModeDrtConfigGroup;
import org.matsim.contrib.drt.run.MultiModeDrtModule;
import org.matsim.contrib.dvrp.run.DvrpConfigGroup;
import org.matsim.contrib.dvrp.run.DvrpModule;
import org.matsim.contrib.dvrp.run.DvrpQSimComponents;
import org.matsim.contrib.zone.skims.DvrpTravelTimeMatrixParams;
import org.matsim.core.config.CommandLine;
import org.matsim.core.config.CommandLine.ConfigurationException;
import org.matsim.core.config.Config;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.config.groups.QSimConfigGroup.EndtimeInterpretation;
import org.matsim.core.config.groups.QSimConfigGroup.StarttimeInterpretation;
import org.matsim.core.config.groups.ScoringConfigGroup.ActivityParams;
import org.matsim.core.config.groups.ScoringConfigGroup.ModeParams;
import org.matsim.core.controler.Controler;
import org.matsim.core.controler.OutputDirectoryHierarchy.OverwriteFileSetting;
import org.matsim.core.scenario.ScenarioUtils;

import com.fasterxml.jackson.core.JsonGenerationException;
import com.fasterxml.jackson.databind.JsonMappingException;

public class RunSimulation {

	static public void main(String[] args) throws ConfigurationException, JsonGenerationException, JsonMappingException,
			IOException, InterruptedException {
		CommandLine cmd = new CommandLine.Builder(args) //
				.requireOptions("demand-path", "fleet-path", "network-path", "travel-time-matrix-path", "threads",
						"cell-size", "output-path") //
				.build();

		String demandPath = cmd.getOptionStrict("demand-path");
		String fleetPath = cmd.getOptionStrict("fleet-path");
		String networkPath = cmd.getOptionStrict("network-path");
		String travelTimeMatrixPath = cmd.getOptionStrict("travel-time-matrix-path");
		String outputPath = cmd.getOptionStrict("output-path");
		int threads = Integer.parseInt(cmd.getOptionStrict("threads"));
		int cellSize = Integer.parseInt(cmd.getOptionStrict("cell-size"));

		// Prepare configuration
		Config config = ConfigUtils.createConfig();
		config.plans().setInputFile(demandPath);
		config.network().setInputFile(networkPath);

		config.global().setNumberOfThreads(threads);

		config.controller().setOutputDirectory(outputPath);
		config.controller().setOverwriteFileSetting(OverwriteFileSetting.deleteDirectoryIfExists);
		config.controller().setLastIteration(0);

		config.qsim().setStartTime(0.0);
		config.qsim().setSimStarttimeInterpretation(StarttimeInterpretation.onlyUseStarttime);

		config.qsim().setEndTime(30.0 * 3600.0);
		config.qsim().setSimEndtimeInterpretation(EndtimeInterpretation.onlyUseEndtime);

		config.qsim().setFlowCapFactor(1e9);
		config.qsim().setStorageCapFactor(1e9);

		ModeParams modeScoringParams = new ModeParams("drt");
		config.scoring().addModeParams(modeScoringParams);

		ActivityParams activityScoringParams = new ActivityParams("generic");
		activityScoringParams.setScoringThisActivityAtAll(false);
		config.scoring().addActivityParams(activityScoringParams);

		DvrpConfigGroup dvrpConfig = new DvrpConfigGroup();
		config.addModule(dvrpConfig);

		MultiModeDrtConfigGroup drtConfig = new MultiModeDrtConfigGroup();
		config.addModule(drtConfig);

		DrtConfigGroup modeConfig = new DrtConfigGroup();
		drtConfig.addParameterSet(modeConfig);

		modeConfig.mode = "drt";
		modeConfig.vehiclesFile = fleetPath;
		modeConfig.stopDuration = 60.0; // will be overridden individually
		modeConfig.updateRoutes = false; // TODO: enable for congestion mitigation

		// constraints will be overridden individually per request
		DefaultDrtOptimizationConstraintsSet optimizationParams = (DefaultDrtOptimizationConstraintsSet) modeConfig
				.addOrGetDrtOptimizationConstraintsParams()
				.addOrGetDefaultDrtOptimizationConstraintsSet();
		optimizationParams.maxWaitTime = 300.0; // will be overridden individually
		optimizationParams.maxTravelTimeAlpha = 2.0;
		optimizationParams.maxTravelTimeBeta = 300.0;

		ExtensiveInsertionSearchParams searchParams = new ExtensiveInsertionSearchParams();
		modeConfig.addParameterSet(searchParams);

		DvrpTravelTimeMatrixParams matrixParams = dvrpConfig.getTravelTimeMatrixParams();
		matrixParams.cachePath = travelTimeMatrixPath;
		matrixParams.maxNeighborDistance = 0.0;

		SquareGridZoneSystemParams grid = new SquareGridZoneSystemParams();
		matrixParams.addParameterSet(grid);
		grid.cellSize = cellSize;

		PrebookingParams prebookingParams = new PrebookingParams();
		modeConfig.addParameterSet(prebookingParams);

		// TODO for disruption
		// prebookingParams.maximumPassengerDelay = maximumPassengerDelay;
		prebookingParams.abortRejectedPrebookings = true;

		DrtConfigs.adjustMultiModeDrtConfig(MultiModeDrtConfigGroup.get(config), config.scoring(), config.routing());

		// set up scenario
		Scenario scenario = ScenarioUtils.loadScenario(config);
		scenario.getPopulation()
				.getFactory()
				.getRouteFactories()
				.setRouteFactory(DrtRoute.class, new DrtRouteFactory());

		// set up controller
		Controler controller = new Controler(scenario);
		controller.addOverridingModule(new DvrpModule());
		controller.addOverridingModule(new MultiModeDrtModule());
		controller.configureQSimComponents(DvrpQSimComponents.activateAllModes(drtConfig));

		// service level and stop duration
		controller.addOverridingModule(new MaiaModeModule(modeConfig));

		// group identification and exclusivity
		controller.addOverridingQSimModule(new MaiaModeQSimModule(modeConfig.getMode()));

		controller.addOverridingQSimModule(new DrtInsertionModule(modeConfig) //
				.withExclusivity(MaiaExclusivityVoter.class));

		// prebooking
		AttributeBasedPrebookingLogic.install(controller, modeConfig);

		// run simulation
		controller.run();

		/*
		 * Double maximumPassengerDelay = Double.POSITIVE_INFINITY;
		 * if (cmd.hasOption("maximum-passenger-delay")) {
		 * maximumPassengerDelay =
		 * Double.valueOf(cmd.getOptionStrict("maximum-passenger-delay"));
		 * }
		 * 
		 * controler.addOverridingModule(new
		 * DisruptionModule(drtConfigGroup.getMode()));
		 * controler.addOverridingQSimModule(new DisruptionQSimModule());
		 */
	}
}
