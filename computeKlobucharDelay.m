function T_iono = computeKlobucharDelay(receiver_pos, sat_pos, gps_time, alpha, beta)
    % Compute ionospheric delay using the Klobuchar model
    % Inputs:
    %   receiver_pos: [x, y, z] ECEF coordinates of receiver (m)
    %   sat_pos: [x, y, z] ECEF coordinates of satellite (m)
    %   gps_time: GPS time in seconds of week
    %   alpha: [alpha0, alpha1, alpha2, alpha3] Klobuchar coefficients
    %   beta: [beta0, beta1, beta2, beta3] Klobuchar coefficients
    % Output:
    %   T_iono: Ionospheric delay in seconds

    % Constants
    Re = 6378137; % Earth radius (m)
    h_iono = 350e3; % Ionospheric shell height (m)

    % Validate inputs
    if ~isequal(size(alpha), [1 4]) || ~isequal(size(beta), [1 4])
        error('alpha and beta must be 1x4 vectors');
    end
    if any(isnan(alpha)) || any(isnan(beta))
        warning('NaN detected in alpha or beta; using default values');
        alpha = [0, 0, 0, 0]; % Fallback to zero coefficients
        beta = [72000, 0, 0, 0]; % Fallback to minimum period
    end

    % Convert receiver position to WGS84 (latitude, longitude in radians)
    wgs84_coord = convertECEFtoWGS84(receiver_pos(1), receiver_pos(2), receiver_pos(3));
    lon = deg2rad(wgs84_coord(1)); % Longitude in radians
    lat = deg2rad(wgs84_coord(2)); % Latitude in radians

    % Compute satellite elevation and azimuth
    ecef_to_enu = [
        -sin(lon), cos(lon), 0;
        -sin(lat)*cos(lon), -sin(lat)*sin(lon), cos(lat);
        cos(lat)*cos(lon), cos(lat)*sin(lon), sin(lat)
    ]; % 3x3 matrix
    rel_pos = sat_pos - receiver_pos; % 1x3 row vector
    enu_pos = ecef_to_enu * rel_pos'; % Transpose to 3x1
    azimuth = atan2(enu_pos(1), enu_pos(2));
    elevation = atan2(enu_pos(3), sqrt(enu_pos(1)^2 + enu_pos(2)^2));
    elevation = max(elevation, 0);

    % Klobuchar model calculations
    psi = 0.0137 / (elevation / pi + 0.11) - 0.022;
    phi_i = lat + psi * cos(azimuth);
    phi_i = max(min(phi_i, 0.416), -0.416);
    lambda_i = lon + (psi * sin(azimuth)) / cos(phi_i);
    phi_m = phi_i + 0.064 * cos(lambda_i - 1.617);

    % Debug dimensions
    if ~isscalar(phi_m)
        error('phi_m is not a scalar: size %s', mat2str(size(phi_m)));
    end
    if ~isscalar(lambda_i)
        error('lambda_i is not a scalar: size %s', mat2str(size(lambda_i)));
    end

    t = 43200 * lambda_i / pi + gps_time;
    t = mod(t, 86400);
    if ~isscalar(t)
        error('t is not a scalar: size %s', mat2str(size(t)));
    end

    A = sum(alpha .* (phi_m.^[0,1,2,3]));
    A = max(A, 0);
    P = sum(beta .* (phi_m.^[0,1,2,3]));
    P = max(P, 72000);
    if ~isscalar(P)
        error('P is not a scalar: size %s', mat2str(size(P)));
    end

    X = 2 * pi * (t - 50400) / P;
    if abs(X) < 1.57
        T_iono = 5e-9 + A * (1 - X^2/2 + X^4/24);
    else
        T_iono = 5e-9;
    end
    F = 1.0 + 16.0 * (0.53 - elevation / pi)^3;
    T_iono = F * T_iono;

    % Debug output
    % fprintf('Ionospheric delay: %.2f meters\n', T_iono * 299792458);
end