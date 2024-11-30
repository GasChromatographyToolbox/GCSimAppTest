module App

using GenieFramework
using DataFrames
using GasChromatographySimulator
using Stipple
using StippleUI#.Tables: DataTable

@genietools

Stipple.Layout.add_css("css/my-style.css")
# Reactive code
@app begin
# == REACTIVE VARIABLES ==
    # @out variables can only be modified by the backend
    # @in variables can be modified by both the backend and the browser
    # variables must be initialized with constant values, or variables defined outside of the @app block

    # input variables
    @in column_length = 30.0
    @in column_diameter = 0.25
    @in film_thickness = 0.25
    @in stationary_phase = "DB5"
    @in stationary_phase_options = ["DB5", "Wax", "SPB50"]
    @in gas = "He"
    @in gas_options = ["H2", "He", "N2"]
    @in flow_rate = 1.0
    @in outlet_pressure = "atmospheric"
    @in outlet_pressure_options = ["atmospheric", "vacuum"]
    @in number_of_heating_rates = 2
    @in temperature_plateaus = [40.0, 100.0, 200.0]
    @in temperature_hold_times = [1.0, 2.0, 5.0]
    @in heating_rates = [10.0, 20.0]
    @in run_simulation = false
    @in refresh_ui = false

    # result of the simulation
    @out simulation_results = DataTable(DataFrame(
        name = String[], 
        tR = Float64[], 
        τR = Float64[]
    ))
    #@out result_names = ["sub1", "sub2", "sub3"]
    #@out result_tR = [1.0, 2.0, 3.0]
    #@out result_τR = [0.1, 0.2, 0.3]

    # == REACTIVE HANDLERS ==
    # reactive handlers watch a variable and execute a block of code when its value changes
    @onchange number_of_heating_rates begin
        @info "number_of_heating_rates changed to $(number_of_heating_rates)"
        # Ensure arrays have correct length based on number_of_heating_rates
        current_length = length(temperature_plateaus)
        target_length = number_of_heating_rates + 1

        if current_length < target_length
            # Add new elements
            push!(temperature_plateaus, temperature_plateaus[end]+10.0)
            push!(temperature_hold_times, 0.0)
            if length(heating_rates) < number_of_heating_rates
                push!(heating_rates, heating_rates[end])
            end
        elseif current_length > target_length
            # Remove elements
            pop!(temperature_plateaus)
            pop!(temperature_hold_times)
            if length(heating_rates) > number_of_heating_rates
                pop!(heating_rates)
            end
        end

        # Force reactive updates by creating new array copies
        temperature_plateaus = copy(temperature_plateaus)
        temperature_hold_times = copy(temperature_hold_times)
        heating_rates = copy(heating_rates)

        @info "Temperature plateaus: $(temperature_plateaus)"
        @info "Temperature hold times: $(temperature_hold_times)"
        @info "Heating rates: $(heating_rates)"
        # Trigger a refresh of the UI
        refresh_ui = !refresh_ui
    end

    @onbutton run_simulation begin
        @info "Running simulation"
        # TODO: run the simulation
        simulation_results = GC_simulation(column_length, column_diameter, film_thickness, stationary_phase, gas, flow_rate, outlet_pressure, temperature_plateaus, temperature_hold_times, heating_rates)
    end
end

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
                        heating_rates)

    L = column_length
    d = column_diameter
    df = film_thickness
    F = flow_rate
    T_plateaus = temperature_plateaus
    T_hold_times = temperature_hold_times
    rT = heating_rates

    # column settings
    column = GasChromatographySimulator.Column(L, d*1e-3, df*1e-6, stationary_phase, gas)
    # program settings
    time_steps, temperature_steps = temperature_program(T_plateaus, T_hold_times, rT)
    if outlet_pressure == "atmospheric"
        p_out = 101300.0
    elseif outlet_pressure == "vacuum"
        p_out = 0.0
    else
        error("Invalid outlet pressure. Must be either 'atmospheric' or 'vacuum'.")
    end
    program = GasChromatographySimulator.Program(time_steps, temperature_steps, fill(F, length(time_steps))./(60e6), fill(p_out, length(time_steps)), L)
    
    # sunstances
    # placeholder for now
    # TODO: load real data
    substances = [
        GasChromatographySimulator.Substance("sub1", "0-0-1", 273.15+40.0, 30.0, 80.0, 1e-3, "test", 1e-8, 0.0, 0.0),
        GasChromatographySimulator.Substance("sub2", "0-0-2", 273.15+50.0, 33.0, 100.0, 1e-3, "test", 1e-8, 0.0, 0.0),
        GasChromatographySimulator.Substance("sub3", "0-0-3", 273.15+60.0, 27.0, 90.0, 1e-3, "test", 1e-8, 0.0, 0.0)
    ]

    # options
    options = GasChromatographySimulator.Options(
        ng=false, 
        control="Flow"
    )

    parameters = GasChromatographySimulator.Parameters(column, program, substances, options)
    @info "Converted parameters:" parameters
    # Run the simulation 
    sim = GasChromatographySimulator.simulate(parameters)[1]
    df = DataFrame(
        name = sim.Name, 
        tR = sim.tR./60.0, 
        τR = sim.τR./60.0
    )

    simulation_results = DataTable(df)
    @info "Simulation results:" df

    return simulation_results

    # placeholder simulation
    #return ["sub1", "sub2", "sub3"], [1.2, 2.4, 3.6], [0.2, 0.4, 0.6]
end

# == Pages ==
# register a new route and the page that will be loaded on access
@page("/", "app.jl.html")
end
