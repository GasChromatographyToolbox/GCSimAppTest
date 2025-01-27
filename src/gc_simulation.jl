function temperature_program(temperature_plateaus, temperature_hold_times, heating_rates)
	CP = []
	for i=1:length(temperature_plateaus)
		if i < length(temperature_plateaus)
			append!(CP, [temperature_plateaus[i], temperature_hold_times[i], heating_rates[i]])
		else
			append!(CP, [temperature_plateaus[i], temperature_hold_times[i]])
		end
	end
    time_steps, temperature_steps = GasChromatographySimulator.conventional_program(CP; time_unit="min")
	return time_steps, temperature_steps
end

function GC_simulation(column_length, 
                        column_diameter, 
                        film_thickness, 
                        stationary_phase, 
                        gas, 
                        flow_rate, 
                        outlet_pressure, 
                        temperature_plateaus, 
                        temperature_hold_times, 
                        heating_rates,
                        database,
                        substance_names)

    L = column_length
    d = column_diameter
    df = film_thickness
    F = flow_rate
    T_plateaus = temperature_plateaus
    T_hold_times = temperature_hold_times
    rT = heating_rates

    # column settings
    column = GasChromatographySimulator.Column(L, d*1e-3, df*1e-6, stationary_phase, gas)
    @info "Column settings:" column
    # program settings
    time_steps, temperature_steps = temperature_program(T_plateaus, T_hold_times, rT)
    @info "Program settings:" time_steps, temperature_steps
    if outlet_pressure == "atmospheric"
        p_out = 101300.0
    elseif outlet_pressure == "vacuum"
        p_out = 0.0
    else
        error("Invalid outlet pressure. Must be either 'atmospheric' or 'vacuum'.")
    end
    program = GasChromatographySimulator.Program(time_steps, temperature_steps, fill(F, length(time_steps))./(60e6), fill(p_out, length(time_steps)), L)
    
    # substances
    # placeholder for now
    # TODO: load real data
    #substances = [
    #    GasChromatographySimulator.Substance("sub1", "0-0-1", 273.15+40.0, 30.0, 80.0, 1e-3, "test", 1e-8, 0.0, 0.0),
    #    GasChromatographySimulator.Substance("sub2", "0-0-2", 273.15+50.0, 33.0, 100.0, 1e-3, "test", 1e-8, 0.0, 0.0),
    #    GasChromatographySimulator.Substance("sub3", "0-0-3", 273.15+60.0, 27.0, 90.0, 1e-3, "test", 1e-8, 0.0, 0.0)
    #]
    substances = GasChromatographySimulator.load_solute_database(database, column.sp, column.gas, substance_names, zeros(length(substance_names)), zeros(length(substance_names)))
    @info "Substances:" substances

    # options
    options = GasChromatographySimulator.Options(
        ng=true, 
        control="Flow"
    )
    @info "Options:" options
    parameters = GasChromatographySimulator.Parameters(column, program, substances, options)
    @info "Converted parameters:" parameters
    # Run the simulation 
    sim = GasChromatographySimulator.simulate(parameters)[1]
    height = GasChromatographySimulator.chromatogram(sim.tR./60.0, sim.tR./60.0, sim.τR./60.0)
    simulation_results = DataFrame(
        name = sim.Name, 
        tR = replace(round.(sim.tR./60.0, digits=3), NaN => "--"), 
        τR = replace(round.(sim.τR, digits=2), NaN => "--"),
        Telu = replace(round.(sim.TR, digits=2), NaN => "--"),
        Res = replace(round.(sim.Res, digits=3), NaN => "--"),
        height = replace(round.(height, digits=3), NaN => "--")
        # NaN values seem to cause issues with the DataTable/Vue.js
    )
    @info "Simulation results:" simulation_results

    # chromatogram
    tEnd = sum(time_steps)/60.0
    t = 0.0:tEnd/10000:tEnd
    y = GasChromatographySimulator.chromatogram(t, simulation_results.tR, simulation_results.τR./60.0)
    chromatogram = DataFrame(
        t = t,
        y = y
    )

    return simulation_results, chromatogram 
end
