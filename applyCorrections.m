function [GPS_Coordinate, SxClockError] = applyCorrections(GPS, Obs, Nav, RxClockError)
    % Apply Earth rotation and satellite clock corrections
    c = 299792458; % Speed of light (m/s)
    omega_E = 7.2921151467e-05; % Earth rotation rate (rad/s)

    % Earth rotation correction
    t_emission = Obs.C1 / c;
    WT = omega_E * t_emission;
    Rotation_r(1,1) = cos(WT);
    Rotation_r(1,2) = sin(WT);
    Rotation_r(1,3) = 0;
    Rotation_r(2,1) = -sin(WT);
    Rotation_r(2,2) = cos(WT);
    Rotation_r(2,3) = 0;
    Rotation_r(3,1) = 0;
    Rotation_r(3,2) = 0;
    Rotation_r(3,3) = 1;
    GPS_Coordinate = GPS * Rotation_r;

    % Satellite clock error
    half_week = 3.5 * 60 * 60 * 24;
    t = Obs.Time_in_GPS - t_emission - RxClockError;
    tk = (t - Nav.Toe_time);
    if (tk > half_week)
        tk = tk - (2 * half_week);
    elseif (tk < -half_week)
        tk = tk + (2 * half_week);
    end
    SxClockError = c * (Nav.SV_Clock_Bias + (Nav.SV_Clock_drift) * tk + (Nav.SV_Clock_drift_rate) * tk^2);
end
