function [elevation, azimuth] = calculateElevationAzimuth(receiverPosition, satellitePosition)
    % Calculate elevation and azimuth angles from receiver to satellite
    % receiverPosition: ECEF coordinates of the receiver [X, Y, Z] (m)
    % satellitePosition: ECEF coordinates of the satellite [X, Y, Z] (m)

    X_r = receiverPosition(1);
    Y_r = receiverPosition(2);
    Z_r = receiverPosition(3);

    X_s = satellitePosition(1);
    Y_s = satellitePosition(2);
    Z_s = satellitePosition(3);

    % Calculate the vector from the receiver to the satellite
    dX = X_s - X_r;
    dY = Y_s - Y_r;
    dZ = Z_s - Z_r;

    % Convert ECEF to ENU (East, North, Up) coordinates
    wgs84_coord = convertECEFtoWGS84(X_r, Y_r, Z_r); % Use existing convertECEFtoWGS84
    lat = wgs84_coord(2); % Latitude from WGS84 coordinates
    lon = wgs84_coord(1); % Longitude from WGS84 coordinates

    lat_rad = deg2rad(lat);
    lon_rad = deg2rad(lon);

    % Rotation matrix from ECEF to ENU
    R = [-sin(lon_rad), cos(lon_rad), 0;
         -sin(lat_rad)*cos(lon_rad), -sin(lat_rad)*sin(lon_rad), cos(lat_rad);
          cos(lat_rad)*cos(lon_rad), cos(lat_rad)*sin(lon_rad), sin(lat_rad)];

    % Rotate the vector from ECEF to ENU
    ENU = R * [dX; dY; dZ];
    E = ENU(1);
    N = ENU(2);
    U = ENU(3);

    % Calculate azimuth and elevation
    azimuth = atan2(E, N); % Azimuth angle (radians)
    elevation = atan2(U, sqrt(E^2 + N^2)); % Elevation angle (radians)

    % Convert to degrees
    azimuth = rad2deg(azimuth);
    elevation = rad2deg(elevation);

    % Ensure azimuth is between 0 and 360 degrees
    if azimuth < 0
        azimuth = azimuth + 360;
    end
end

function skyPlot(receiverPosition, satellitePositions)
    % Input:
    % receiverPosition: ECEF coordinates of the receiver [X, Y, Z] (m)
    % satellitePositions: Nx3 matrix of ECEF coordinates for satellites [X, Y, Z] (m)

    numSatellites = size(satellitePositions, 1);
    elevation = zeros(numSatellites, 1);
    azimuth = zeros(numSatellites, 1);

    % Calculate elevation and azimuth for each satellite
    for i = 1:numSatellites
        [elevation(i), azimuth(i)] = calculateElevationAzimuth(receiverPosition, satellitePositions(i, :));
    end

    % Plot the sky plot
    figure;
    polarplot(deg2rad(azimuth), 90 - elevation, 'o'); % Zenith angle = 90 - elevation
    title('Sky Plot');
    rlim([0 90]); % Limit radius to 90 degrees
    thetalim([0 360]); % Limit azimuth to full circle
    set(gca, 'ThetaZeroLocation', 'top', 'ThetaDir', 'clockwise');
    grid on;
    legend('Satellites');
end
