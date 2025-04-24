function wgs84_coord = convertECEFtoWGS84(X, Y, Z)
    % Convert ECEF to WGS84 coordinates
    % Constants
    a = 6378137; % Semi-major axis
    f = 1 / 298.257223563; % Flattening
    b = a * (1 - f); % Semi-minor axis

    % Auxiliary values
    P = sqrt(X^2 + Y^2);
    e = sqrt(((a^2) - (b^2)) / a^2); % First eccentricity

    % Initial latitude
    Latitude = atan2(Z, (P * (1 - e^2)));

    % Refine latitude
    for i = 1:10000
        N = a / sqrt(1 - e^2 * sin(Latitude)^2); % Prime vertical
        Altitude = (P / cos(Latitude)) - N; % Altitude
        Latitude = atan2(Z, (P * (1 - e^2 * (N / (N + Altitude))))); % Latitude
    end

    % Compute longitude and latitude
    Longitude = (atan2(Y, X)) * 180 / pi;
    Latitude = Latitude * 180 / pi;

    wgs84_coord = [Longitude; Latitude; Altitude];
end
