function GPS = computeSatellitePosition(Nav, Sate_Row, Obs, RxClockError)
    % Calculate satellite position in ECEF
    % Constants
    c = 299792458; % Speed of light (m/s)
    GM = 3.986005e+14; % Earth's GM (m^3/s^2)
    omega_E = 7.2921151467e-05; % Earth rotation rate (rad/s)

    % Semi-major axis
    semi_major_axis = (Nav(Sate_Row).sqrt_a)^2;
    a = semi_major_axis;

    % Time from ephemeris epoch
    half_week = 3.5 * 60 * 60 * 24;
    t_emission = Obs.C1 / c;
    t = Obs.Time_in_GPS - t_emission - RxClockError;
    tk = (t - Nav(Sate_Row).Toe_time);
    if (tk > half_week)
        tk = tk - (2 * half_week);
    elseif (tk < -half_week)
        tk = tk + (2 * half_week);
    end

    % Mean motion
    n0 = sqrt(GM / (a^3));
    n = n0 + Nav(Sate_Row).Delta_N;

    % Mean anomaly
    M = Nav(Sate_Row).M0 + (n * tk);

    % Eccentric anomaly
    n = 1;
    E = 1;
    E0 = M;
    while n <= 30 && abs(E0 - E) > 10^(-14)
        E_new = M + (Nav(Sate_Row).e) * sin(E);
        E = E0;
        E0 = E_new;
        n = n + 1;
    end

    % True anomaly
    True_Anomaly = 2 * atan(sqrt((1 + Nav(Sate_Row).e) / (1 - Nav(Sate_Row).e)) * tan(E / 2));

    % Argument of latitude
    phi = True_Anomaly + Nav(Sate_Row).Omega;

    % Orbit radius
    r = a * (1 - Nav(Sate_Row).e * cos(E));
    delta_r = Nav(Sate_Row).Crs * sin(2 * phi) + Nav(Sate_Row).Crc * cos(2 * phi);
    Corrected_Radius = r + delta_r;

    % Corrected inclination
    inclination_i = Nav(Sate_Row).i0 + Nav(Sate_Row).IDOT * tk;
    delta_i = Nav(Sate_Row).CIS * sin(2 * phi) + Nav(Sate_Row).Cic * cos(2 * phi);
    Corrected_Inclination = inclination_i + delta_i;

    % Corrected argument of latitude
    delta_phi = Nav(Sate_Row).Cus * sin(2 * phi) + Nav(Sate_Row).Cuc * cos(2 * phi);
    Corrected_ArgLat = phi + delta_phi;

    % Orbital plane coordinates
    X0 = Corrected_Radius * cos(Corrected_ArgLat);
    Y0 = Corrected_Radius * sin(Corrected_ArgLat);

    % Longitude of ascending node
    Corrected_omega = Nav(Sate_Row).Omega_0 + (Nav(Sate_Row).Omega_dot - omega_E) * tk - omega_E * Nav(Sate_Row).Toe_time;

    % Convert to ECEF coordinates
    GPS(1) = X0 * cos(Corrected_omega) - Y0 * cos(Corrected_Inclination) * sin(Corrected_omega);
    GPS(2) = X0 * sin(Corrected_omega) + Y0 * cos(Corrected_Inclination) * cos(Corrected_omega);
    GPS(3) = Y0 * sin(Corrected_Inclination);
end
