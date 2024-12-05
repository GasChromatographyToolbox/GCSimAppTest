module GCSim

using GenieFramework
using DataFrames
using CSV
using GasChromatographySimulator
using Stipple
using StippleUI#.Tables: DataTable
using PlotlyBase

# Reactive code
@app begin
    # place the reactive code for the GCsim page here

    @page("/gcsim", "views/gcsim.jl.html")
end

