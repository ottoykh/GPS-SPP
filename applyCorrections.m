function [GPS_Coordinate, SxClockError] = applyCorrections(GPS, Obs, Nav, RxClockError, Approx_X, Approx_Y, Approx_Z, ionAlpha, ionBeta)
    % Apply Earth rotation, satellite clock, and ionospheric corrections
    % Inputs:
    %   GPS: Satellite position [X, Y, Z]
    %   Obs: Observation data (C1, Time_in_GPS, PRN)
    %   Nav: Navigation data (clock parameters, ephemeris)
    %   RxClockError: Receiver clock error (s)
    %   Approx_X, Approx_Y, Approx_Z: Approximate receiver ECEF coordinates (m)
    %   ionAlpha: Klobuchar alpha coefficients [alpha0, alpha1, alpha2, alpha3]
    %   ionBeta: Klobuchar beta coefficients [beta0, beta1, beta2, beta3]
    % Outputs:
    %   GPS_Coordinate: Corrected satellite coordinates [X, Y, Z]
    %   SxClockError: Satellite clock error (m)

    % Constants
    c = 299792458; % Speed of light (m/s)
    omega_E = 7.2921151467e-05; % Earth rotation rate (rad/s)

    % Earth rotation correction
    t_emission = Obs.C1 / c;
    WT = omega_E * t_emission;
    Rotation_r = [
        cos(WT), sin(WT), 0;
        -sin(WT), cos(WT), 0;
        0, 0, 1
    ];
    GPS_Coordinate = (Rotation_r * GPS')'; % Apply rotation to [X, Y, Z]

    % Satellite clock error
    half_week = 3.5 * 60 * 60 * 24;
    t = Obs.Time_in_GPS - t_emission - RxClockError;
    tk = t - Nav.Toe_time;
    if tk > half_week
        tk = tk - (2 * half_week);
    elseif tk < -half_week
        tk = tk + (2 * half_week);
    end
    SxClockError = c * (Nav.SV_Clock_Bias + Nav.SV_Clock_drift * tk + Nav.SV_Clock_drift_rate * tk^2);

    % Ionospheric correction using Klobuchar model
    receiver_pos = [Approx_X, Approx_Y, Approx_Z];
    sat_pos = GPS_Coordinate;
    gps_time = Obs.Time_in_GPS;
    T_iono = computeKlobucharDelay(receiver_pos, sat_pos, gps_time, ionAlpha, ionBeta);

    % Apply corrections to pseudorange
    Obs.C1 = Obs.C1 + T_iono * c - SxClockError;
end