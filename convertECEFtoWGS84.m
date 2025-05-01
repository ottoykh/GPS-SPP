function wgs84_coord = convertECEFtoWGS84(X, Y, Z)
    % Convert ECEF to WGS84 coordinates
    % Inputs: X, Y, Z (ECEF coordinates in meters)
    % Output: wgs84_coord = [Longitude; Latitude; Altitude] (degrees, degrees, meters)

    % Constants
    a = 6378137; % Semi-major axis
    f = 1 / 298.257223563; % Flattening
    b = a * (1 - f); % Semi-minor axis
    e2 = ((a^2) - (b^2)) / a^2; % First eccentricity squared

    % Auxiliary values
    P = sqrt(X^2 + Y^2);

    % Handle poles (P ≈ 0)
    if P < 1e-10
        Longitude = 0; % Arbitrary, as longitude is undefined at poles
        if Z > 0
            Latitude = pi/2; % North pole
            Altitude = Z - b;
        else
            Latitude = -pi/2; % South pole
            Altitude = -Z - b;
        end
        wgs84_coord = [Longitude * 180/pi; Latitude * 180/pi; Altitude];
        return;
    end

    % Initial latitude
    Latitude = atan2(Z, P);

    % Refine latitude until convergence
    max_iterations = 10000;
    tolerance = 1e-10; % Radians 
    for i = 1:max_iterations
        N = a / sqrt(1 - e2 * sin(Latitude)^2); % Prime vertical
        Altitude = (P / cos(Latitude)) - N; % Altitude
        new_Latitude = atan2(Z, (P * (1 - e2 * (N / (N + Altitude)))));
        if abs(new_Latitude - Latitude) < tolerance
            Latitude = new_Latitude;
            break;
        end
        Latitude = new_Latitude;
    end

    % Compute longitude and convert to degrees
    Longitude = atan2(Y, X) * 180 / pi;
    Latitude = Latitude * 180 / pi;

    wgs84_coord = [Longitude; Latitude; Altitude];
end