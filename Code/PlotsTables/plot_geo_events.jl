function plot_geo_events(
    data_ports::String,     # where the file ports is located with the location 
    results_folder::String; # where to save the final charts 
    # Optional arguments 
    palette_states = :PuBu_6,                     # palette states' colors 
    color_location = RGB(0.8500, 0.3250, 0.0980), # color event 
    marker_type    = :circle,                     # shape of the marker 
    size_marker    = 18,                          # size marker 
    size_plot_2    = (950,500)                    # size second plot    
    )

    # --------------------------------------------------------------------------
    # 1 - Load Geo Chart 
    # -------------------------------------------------------------------------- 
    path     = GeoMakie.assetpath("vector", "countries.geo.json")
    json_str = read(path, String)
    worldCountries = GeoJSON.read(json_str)

    # Set latitude and longitude 
    n     = length(worldCountries)
    lons  = -180:180
    lats  = -90:90
    field = [exp(cosd(l)) + 3(y/90) for l in lons, y in lats]

    # Colors plot 
    cc = [RGB(0, 0.4470, 0.7410); RGB(0.8500, 0.3250, 0.0980)];

    # --------------------------------------------------------------------------
    # 2 - Load Coordinates Ports 
    # -------------------------------------------------------------------------- 
    ports  = XLSX.readxlsx(data_ports)["ports2"][:];
    points = [];
    for i in 2:size(ports,1)
        points = [points; (lon = ports[i,3], lat = ports[i,2])]
    end

    # Categories of events 
    cat = unique(ports[2:end,4]);

    # --------------------------------------------------------------------------
    # 3 - Plot Ports all Together 
    # -------------------------------------------------------------------------- 
    fig = Figure(size = (950,450), fontsize = 22, figure_padding=(0, 0, 0, 0));
    ax  = GeoAxis(fig[1,1]; dest = "+proj=wintri", title = "",
                tellheight = true, xticks = [], yticks = [])
    hm2 = poly!(ax, GeoMakie.to_multipoly(worldCountries.geometry);
                color = 1:n, colormap = Reverse(palette_states), strokecolor = :black,
                strokewidth = 0.25)

    # Minimize padding around the map
    Makie.tightlimits!(ax) 

    # Plot scatter points
    Makie.scatter!(ax, markersize = size_marker, color = color_location, 
             marker = marker_type,
             [point.lon for point in points],  # Longitudes
             [point.lat for point in points]); # Latitudes

    # Save plot 
    path = pwd()*"/Results/$results_folder/prel_analysis/location.pdf";
    Makie.save(path, fig);

    # --------------------------------------------------------------------------
    # 4 - Plot by Event 
    # -------------------------------------------------------------------------- 
    fig = Figure(size = size_plot_2, fontsize = 22, figure_padding=(0, 0, 0, 0));
    ax  = GeoAxis(fig[1,1]; dest = "+proj=wintri", title = "",
                  tellheight = true, xticks = [], yticks = [])
    hm2 = poly!(ax, GeoMakie.to_multipoly(worldCountries.geometry);
                color = 1:n, colormap = Reverse(palette_states), strokecolor = :black,
                strokewidth = 0.25)

    # Minimize padding around the map
    Makie.tightlimits!(ax) 

    # Plot scatter points
    scatter1 = Makie.scatter!(ax, markersize = size_marker, color = color_location,  
                              marker = marker_type,
                              [point.lon for point in points[findall(ports[2:end,4] .== cat[1])]],  # Longitudes
                              [point.lat for point in points[findall(ports[2:end,4] .== cat[1])]]); # Latitudes
    scatter2 = Makie.scatter!(ax, markersize = size_marker, color = "goldenrod1", #RGB(0.9290, 0.6940, 0.1250), 
                              marker = marker_type,
                              [point.lon for point in points[findall(ports[2:end,4] .== cat[2])]],  # Longitudes
                              [point.lat for point in points[findall(ports[2:end,4] .== cat[2])]]); # Latitudes
    scatter3 = Makie.scatter!(ax, markersize = size_marker, color = "magenta3",# "#BA55D3", 
                              marker = marker_type,
                              [point.lon for point in points[findall(ports[2:end,4] .== cat[3])]],  # Longitudes
                              [point.lat for point in points[findall(ports[2:end,4] .== cat[3])]]); # Latitudes
    scatter4 = Makie.scatter!(ax, markersize = size_marker, color = "green3", #"#228B22", 
                              marker = marker_type,
                              [point.lon for point in points[findall(ports[2:end,4] .== cat[4])]],  # Longitudes
                              [point.lat for point in points[findall(ports[2:end,4] .== cat[4])]]); # Latitudes
    
    # Plot legend at the bottom of the chart 
    legend = Legend(fig, [scatter1, scatter2, scatter3, scatter4], orientation = :horizontal,
                    ["Operational", "War/Conflict", "Strike", "Weather/Natural Disaster"], 
                    tellwidth = false, boxcolor = RGB(0.0, 0.0, 0.0), framevisible = false)
    fig[2, 1] = legend;


    # Save plot 
    path = pwd()*"/Results/$results_folder/prel_analysis/location_categories.pdf";
    Makie.save(path, fig);
end
