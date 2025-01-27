using Pkg.TOML

function get_version()
    project_path = joinpath(@__DIR__, "../Project.toml")
    version = if isfile(project_path)
        project = TOML.parsefile(project_path)
        get(project, "version", "unknown")
    else
        "unknown"
    end
    
    return Dict(
        "version" => version,
        "build_date" => Dates.format(Dates.now(), "yyyy-mm-dd"),
        "env" => get(ENV, "GENIE_ENV", "unknown")
    )
end