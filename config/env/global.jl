# Set environment before loading Genie
ENV["GENIE_ENV"] = "prod" #"prod"

using Genie, Logging
include("../../src/utils.jl")

# App-wide constants
const APP_NAME = "GasChromatographyToolbox"
const VERSION = get_version()

# Base configuration that's the same across all environments
Genie.Configuration.config!(
    # Core settings
    app_env = ENV["GENIE_ENV"],  # Now uses the environment variable we set

    # Path configurations
    path_config = "config",
    #path_app = "app",
    server_document_root = "public",  # This is the correct setting for public files
)

# Global constants for your app, e.g.
#const SIMULATION_DEFAULTS = Dict(
#    "max_time" => 20.0,
#    "time_step" => 0.1
#)

# Global helper functions, e.g. 
#function format_time(t::Float64)
#    return round(t, digits=2)
#end
