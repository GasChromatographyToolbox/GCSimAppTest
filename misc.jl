# misc function oftne only used once to generate data 

function generate_path_data(chromatogram_df)
    #@info "Generating path data from dataframe with $(nrow(chromatogram_df)) rows"
    #@info "First few rows:" first(chromatogram_df, 5)
    #@info "Data ranges: t=$(extrema(chromatogram_df.t)), y=$(extrema(chromatogram_df.y))"

    # Scale the data to fit the SVG viewBox
    x_scale = 1000 / maximum(chromatogram_df.t)  # Scale x to fit 1000 units width
    y_scale = 194 / maximum(chromatogram_df.y)   # Scale y to fit 194 units height (leaving margin)
    
    #@info "Scale factors: x_scale=$(x_scale), y_scale=$(y_scale)"

    # Generate the SVG path data
    points = ["M 0,194"]  # Start at bottom left
    
    for row in eachrow(chromatogram_df)
        x = row.t * x_scale
        y = 194 - (row.y * y_scale)  # Invert y because SVG coordinates go down
        push!(points, "L $(round(x, digits=2)),$(round(y, digits=2))")
    end
    
    path = join(points, " ")
    #@info "Generated path (first 100 chars):" path[1:min(100,length(path))]
    
    return path
end

function save_chromatogram_path()
    path_data = generate_path_data(DataFrame(CSV.File("public/data/chromatogram.csv", header=1, silencewarnings=true)))
    write("public/data/chromatogram-path.txt", path_data)
end