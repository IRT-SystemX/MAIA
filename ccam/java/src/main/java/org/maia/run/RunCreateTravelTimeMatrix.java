package org.maia.run;

import java.io.File;
import java.io.IOException;

import org.matsim.api.core.v01.Scenario;
import org.matsim.contrib.common.zones.systems.grid.square.SquareGridZoneSystemParams;
import org.matsim.contrib.dvrp.run.DvrpConfigGroup;
import org.matsim.contrib.dvrp.run.DvrpModule;
import org.matsim.contrib.zone.skims.DvrpTravelTimeMatrixParams;
import org.matsim.contrib.zone.skims.TravelTimeMatrix;
import org.matsim.core.config.CommandLine;
import org.matsim.core.config.CommandLine.ConfigurationException;
import org.matsim.core.config.Config;
import org.matsim.core.config.ConfigUtils;
import org.matsim.core.config.groups.QSimConfigGroup.StarttimeInterpretation;
import org.matsim.core.controler.Controler;
import org.matsim.core.controler.OutputDirectoryHierarchy.OverwriteFileSetting;
import org.matsim.core.network.io.MatsimNetworkReader;
import org.matsim.core.scenario.ScenarioUtils;

import com.fasterxml.jackson.core.JsonGenerationException;
import com.fasterxml.jackson.databind.JsonMappingException;

public class RunCreateTravelTimeMatrix {
	static public void main(String[] args) throws ConfigurationException, JsonGenerationException, JsonMappingException,
			IOException, InterruptedException {
		CommandLine cmd = new CommandLine.Builder(args) //
				.requireOptions("network-path", "output-path", "threads", "cell-size") //
				.build();

		String networkPath = cmd.getOptionStrict("network-path");
		String outputPath = new File(".", cmd.getOptionStrict("output-path")).getAbsolutePath();

		int cellSize = Integer.parseInt(cmd.getOptionStrict("cell-size"));
		int threads = Integer.parseInt(cmd.getOptionStrict("threads"));

		if (new File(outputPath).exists()) {
			new File(outputPath).delete();
		}

		Config config = ConfigUtils.createConfig();
		config.global().setNumberOfThreads(threads);
		config.controller().setOutputDirectory(outputPath + "__output");
		config.controller().setOverwriteFileSetting(OverwriteFileSetting.deleteDirectoryIfExists);
		config.qsim().setSimStarttimeInterpretation(StarttimeInterpretation.onlyUseStarttime);

		DvrpConfigGroup dvrpConfig = new DvrpConfigGroup();
		config.addModule(dvrpConfig);

		Scenario scenario = ScenarioUtils.createScenario(config);
		new MatsimNetworkReader(scenario.getNetwork()).readFile(networkPath);

		DvrpTravelTimeMatrixParams matrixParams = dvrpConfig.getTravelTimeMatrixParams();
		matrixParams.maxNeighborDistance = 0.0;
		matrixParams.cachePath = outputPath;

		SquareGridZoneSystemParams grid = new SquareGridZoneSystemParams();
		dvrpConfig.getTravelTimeMatrixParams().addParameterSet(grid);
		grid.cellSize = cellSize;

		new Controler(scenario) //
				.addOverridingModule(new DvrpModule()) //
				.getInjector() //
				.getInstance(TravelTimeMatrix.class);
	}
}
