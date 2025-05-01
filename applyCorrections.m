function [GPS_Coordinate, SxClockError, Corrected_C1] = applyCorrections(GPS, Obs, Nav, RxClockError, Approx_X, Approx_Y, Approx_Z, ionAlpha, ionBeta)
    % Apply satellite clock, ionospheric, and Earth rotation corrections
    % Inputs:
    %   GPS: Satellite position [X, Y, Z] (m)
    %   Obs: Observation data (C1 (m), Time_in_GPS (GPS seconds of week), PRN)
    %   Nav: Navigation data (clock parameters (seconds, seconds/second, seconds/second/second), ephemeris, Toe_time (GPS seconds of week))
    %   RxClockError: Receiver clock error (s)
    %   Approx_X, Approx_Y, Approx_Z: Approximate receiver ECEF coordinates (m)
    %   ionAlpha: Klobuchar alpha coefficients [alpha0, alpha1, alpha2, alpha3]
    %   ionBeta: Klobuchar beta coefficients [beta0, beta1, beta2, beta3]
    % Outputs:
    %   GPS_Coordinate: Corrected satellite coordinates [X, Y, Z] (m)
    %   SxClockError: Satellite clock error (m)
    %   Corrected_C1: Corrected pseudorange (m)

    % Constants
    c = 299792458; % Speed of light (m/s)
    omega_E = 7.2921151467e-05; % Earth rotation rate (rad/s)

    % Satellite clock error
    half_week = 3.5 * 60 * 60 * 24;
    t = Obs.Time_in_GPS - (Obs.C1 / c) - RxClockError;  %Initial estimate of transmission time
    tk = t - Nav.Toe_time;
    if tk > half_week
        tk = tk - (2 * half_week);
    elseif tk < -half_week
        tk = tk + (2 * half_week);
    end
    SxClockError = c * (Nav.SV_Clock_Bias + Nav.SV_Clock_drift * tk + Nav.SV_Clock_drift_rate * tk^2); % Satellite clock error (m)


    % Ionospheric correction using Klobuchar model
    receiver_pos = [Approx_X, Approx_Y, Approx_Z];
    sat_pos = GPS; %Use original GPS position before earth rotation
    gps_time = Obs.Time_in_GPS;
    T_iono = computeKlobucharDelay(receiver_pos, sat_pos, gps_time, ionAlpha, ionBeta); % Ionospheric delay (s)

    % Tropospheric correction (Placeholder - replace with actual model)
    T_tropo = computeTropoDelay(receiver_pos, sat_pos); % Tropospheric delay (m)

    % Apply satellite clock and ionospheric corrections to pseudorange
    Corrected_C1 = Obs.C1 + T_iono * c - SxClockError + T_tropo; % Corrected pseudorange (m)

    % Earth rotation correction (using corrected pseudorange)
    t_emission = Corrected_C1 / c; %Using corrected pseudorange
    WT = omega_E * t_emission;
    Rotation_r = [
        cos(WT), sin(WT), 0;
        -sin(WT), cos(WT), 0;
        0, 0, 1
    ];
    GPS_Coordinate = (Rotation_r * GPS')'; % Apply rotation to [X, Y, Z]

end

function T_tropo = computeTropoDelay(receiver_pos, sat_pos)
    T_tropo = 0; % Placeholder: No tropospheric correction
end
