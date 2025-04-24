function [GPS_Receiver, wgs84_coord] = computeGPSPosition(navFile, obsFile)
    % Compute GPS receiver position from RINEX files
    fprintf('Reading observation data...\n');

    % Read navigation and observation data
    Nav = readNavData(navFile);
    [Obs, Approx_X, Approx_Y, Approx_Z, Obs_Time_of_FirstObs] = readObsData(obsFile);

    % Match PRN and GPS time
    Compare_Nav_PRN = [Nav(:).PRN];
    Compare_Obs_PRN = [Obs(:).PRN];
    Compare_Nav_GPSTime = [Nav(:).Time_in_GPS];
    Compare_Obs_GPSTime = [Obs(:).Time_in_GPS];

    % Initialize position iteration
    c = 299792458; % Speed of light (m/s)
    RxClockError = 0.01;
    RxClockDiff = 1;
    iteration = 0;
    dx = [0.01; 0.01; 0.01; RxClockError];
    Approximate_Coor = [Approx_X; Approx_Y; Approx_Z; RxClockError];

    % Refine receiver position
    Epoch_OBS = length(Obs);
    No_Epoch_Nav = length(Nav);
    while (abs(dx(1,1)) + abs(dx(2,1)) + abs(dx(3,1)) + abs(RxClockDiff)) > 10e-8
        for i = 1:Epoch_OBS
            % Find matching PRNs
            q = 1;
            for b = 1:No_Epoch_Nav
                if isequal(Compare_Nav_PRN(1,b), Compare_Obs_PRN(1,i))
                    RowOfSamePRN(q,i) = b;
                    q = q + 1;
                end
            end
            No_RowOfSamePRN = sum(RowOfSamePRN ~= 0);

            % Find closest GPS time (4-hour validity)
            Difference_Minimum = 4 * 60 * 60;
            for m = 1:No_RowOfSamePRN(i)
                Difference_GPSTime = abs(Compare_Obs_GPSTime(1,i) - Compare_Nav_GPSTime(1,RowOfSamePRN(m,i)));
                if (Difference_GPSTime < Difference_Minimum)
                    Difference_Minimum = Difference_GPSTime;
                    Sate_Row = RowOfSamePRN(m,i);
                end
            end

            % Compute satellite position and apply corrections
            GPS(i,:) = computeSatellitePosition(Nav, Sate_Row, Obs(i), RxClockError);
            [GPS_Coordinate(i,:), SxClockError(i)] = applyCorrections(GPS(i,:), Obs(i), Nav(Sate_Row), RxClockError);

            % Compute receiver position components
            [rho(i), B(i,:), f(i,1)] = computeReceiverPosition(GPS(i,:), Approximate_Coor, Obs(i), SxClockError(i));
        end
        % Compute correction
        dxprevious = RxClockError;
        dx = inv(transpose(B) * B) * transpose(B) * f;
        Approximate_Coor = Approximate_Coor + dx;
        RxClockError = dx(4,1) / c;
        RxClockDiff = RxClockError - dxprevious;
        iteration = iteration + 1;
    end

    % Store receiver position
    GPS_Receiver = zeros(4,1);
    GPS_Receiver(1,1) = Approximate_Coor(1);
    GPS_Receiver(2,1) = Approximate_Coor(2);
    GPS_Receiver(3,1) = Approximate_Coor(3);
    GPS_Receiver(4,1) = Approximate_Coor(4);

    fprintf('ECEF Position: X=%.2f, Y=%.2f, Z=%.2f\n', GPS_Receiver(1,1), GPS_Receiver(2,1), GPS_Receiver(3,1));

    % Convert to WGS84
    wgs84_coord = convertECEFtoWGS84(GPS_Receiver(1,1), GPS_Receiver(2,1), GPS_Receiver(3,1));
    fprintf('WGS84 Position: Lon=%.6f, Lat=%.6f, Alt=%.2f\n', wgs84_coord(1), wgs84_coord(2), wgs84_coord(3));

    % Plot WGS84 position
    plotWGS84Position(wgs84_coord);
end