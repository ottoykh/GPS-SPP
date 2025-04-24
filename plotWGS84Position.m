function plotWGS84Position(wgs84_coord)
    % Plot WGS84 coordinates (latitude, longitude, altitude) on a map with imagery, labels, and zoom level 15
    % Input: wgs84_coord = [Longitude; Latitude; Altitude]
    Longitude = wgs84_coord(1);
    Latitude = wgs84_coord(2);
    Altitude = wgs84_coord(3);

    % Create a new figure
    figure;
    
       % Create a geographic axes
    geoplot(Latitude, Longitude, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
    hold on;

    % Set map basemap to topographic for imagery with labels (requires Mapping Toolbox)
    try
        geobasemap('topographic'); % Imagery-like with place/road labels
    catch
        warning('Mapping Toolbox not available or basemap unsupported. Using basic plot.');
        plot(Longitude, Latitude, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
        xlabel('Longitude (degrees)');
        ylabel('Latitude (degrees)');
        grid on;
        title(sprintf('Receiver Position: Lat=%.6f, Lon=%.6f, Alt=%.2f m', Latitude, Longitude, Altitude));
        hold off;
        return;
    end

    % Calculate bounds for zoom level 15 (approximate street-scale view)
    % Zoom level 15: ~0.010986 degrees/tile at equator, adjusted by cos(latitude) for Mercator projection
    tile_size_deg = 360 / (2^15); % ~0.010986 degrees at zoom level 15
    lat_adjust = cosd(Latitude); % Adjust for latitude (Mercator projection)
    delta_deg = tile_size_deg * 2; % Approximate ±delta for ~1-2 km view
    geolimits([Latitude - delta_deg, Latitude + delta_deg], ...
              [Longitude - delta_deg * lat_adjust, Longitude + delta_deg * lat_adjust]);

    % Add title with coordinates and altitude
    title(sprintf('Receiver Position: Lat=%.6f, Lon=%.6f, Alt=%.2f m', Latitude, Longitude, Altitude));

    % Add axis labels for GeographicAxes
    gx = gca;
    gx.LongitudeLabel.String = 'Longitude';
    gx.LatitudeLabel.String = 'Latitude';

    hold off;
end