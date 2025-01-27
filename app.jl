module App

using GenieFramework
using DataFrames
using CSV
using GasChromatographySimulator
using Stipple
using StippleUI#.Tables: DataTable
using PlotlyBase
include("src/utils.jl")
include("src/gc_simulation.jl")

@genietools

# custom javascript:
# set the browser title of the page based on the route
title_module() = [
    script("""
        document.addEventListener("DOMContentLoaded", function() {
            const titles = {
                '/': 'GasChromatographyToolbox',
                '/gcsim': 'GC Simulation - GasChromatographyToolbox',
                '/about': 'About Me - GasChromatographyToolbox'
            };
            const currentPath = window.location.pathname;
            console.log("Current path:", currentPath);
            console.log("Setting document title");
            document.title = titles[currentPath] || 'GasChromatographyToolbox';
            console.log("title:", document.title);
        });
    """)
]

@deps title_module

# Reactive code
@app begin
    # Load the retention database   
    retention_database = DataFrame(CSV.File("public/data/Database.csv", header=1, silencewarnings=true, stringtype=String))
    substance_names = GasChromatographySimulator.all_solutes("Wax", retention_database)
    phases = unique(retention_database.Phase)
    
# == REACTIVE VARIABLES ==
    # @out variables can only be modified by the backend
    # @in variables can be modified by both the backend and the browser
    # variables must be initialized with constant values, or variables defined outside of the @app block

    # input variables
    @in column_length = 30.0
    @in column_diameter = 0.25
    @in film_thickness = 0.25
    @in stationary_phase = phases[1]
    @in stationary_phase_options = phases
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
    # default data for the default input variables is loaded from the public/data folder
    data_table_options = DataTableOptions(
        columns = [
        Column("name", label="Name", align=:left, sortable=false),
        Column("tR", label="Retention Time (min)", align=:right, sortable=false),
        Column("τR", label="Peak Width (s)", align=:right, sortable=false),
        Column("Telu", label="Elution Temperature (°C)", align=:right, sortable=false),
        Column("Res", label="Resolution", align=:right, sortable=false)
        ]
    )
    pagination = DataTablePagination(
        rows_per_page = 17,  # 0 means show all rows
        page = 1,
        sort_by = :tR,
        descending = false
    )
    @out simulation_results = DataTable(
        DataFrame(CSV.File("public/data/simulation_results.csv", header=1, silencewarnings=true)),
        #DataFrame(
        #    name = String[],
        #    tR = Float64[],
        #    τR = Float64[],
        #    Telu = Float64[],
        #    Res = Float64[],
        #    height = Float64[]
        #),
        data_table_options,
        pagination
    )

    @out chromatogram = DataFrame(CSV.File("public/data/chromatogram.csv", header=1, silencewarnings=true))

    # misc variables
    @out title = "GasChromatographyToolbox"
    @out chromatogram_path = read("public/data/chromatogram-path-animation.txt", String)
    @out @out app_version_info = get_version()

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
        #temperature_plateaus = copy(temperature_plateaus)
        #temperature_hold_times = copy(temperature_hold_times)
        #heating_rates = copy(heating_rates)
        @push temperature_plateaus
        @push temperature_hold_times
        @push heating_rates

        @info "Temperature plateaus: $(temperature_plateaus)"
        @info "Temperature hold times: $(temperature_hold_times)"
        @info "Heating rates: $(heating_rates)"
        # Trigger a refresh of the UI
        refresh_ui = !refresh_ui
    end

    @onbutton run_simulation begin
        #println(stderr, "=== BUTTON CLICKED ===")
        #@info "Button clicked, running simulation"
        #@info "Input parameters:" column_length column_diameter film_thickness stationary_phase gas flow_rate outlet_pressure temperature_plateaus temperature_hold_times heating_rates
        @info "Running simulation"

        try
            results_df, chrom_df = GC_simulation(column_length, column_diameter, film_thickness, stationary_phase, gas, flow_rate, outlet_pressure, temperature_plateaus, temperature_hold_times, heating_rates, retention_database, substance_names)
            
            println(stderr, "=== SIMULATION COMPLETED ===")
            @info "Results:" first(results_df, 3)  # Show first 3 rows
            # Update the DataTables data property
            simulation_results = DataTable(results_df, data_table_options, pagination)
            @push simulation_results

            # save the simulation results to a file
            #CSV.write("public/data/simulation_results.csv", results_df)

            #Update the chromatogram data 
            chromatogram = chrom_df
            @push chromatogram

            # Log the final state
            @info "simulation_results updated:" simulation_results
            @info "chromatogram updated:" chromatogram

        catch e
            println(stderr, "=== SIMULATION ERROR ===")
            @error "Simulation failed" exception=(e, catch_backtrace())
        end
        
    end
end



# == Pages ==
# register a new route and the page that will be loaded on access
@page("/", "views/index.jl.html", layout = "layouts/base_layout.html")
@page("/gcsim", "views/gcsim.jl.html", layout = "layouts/base_layout.html")
@page("/about", "views/about.jl.html", layout = "layouts/base_layout.html")
@page("/legal/privacy_notice", "views/legal/privacy_notice.html", layout = "layouts/base_layout.html")
@page("/legal/legal_notice", "views/legal/legal_notice.html", layout = "layouts/base_layout.html")
end
