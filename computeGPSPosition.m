function [GPS_Receiver, wgs84_coord] = computeGPSPosition(navFile, obsFile, elevationCutoff )
    % Compute GPS receiver position from RINEX files
    % Inputs:
    %   navFile: Path to the navigation data file (RINEX)
    %   obsFile: Path to the observation data file (RINEX)
    %   elevation_angle_cutoff: Elevation mask angle (degrees)
    % Outputs:
    %   GPS_Receiver: 4x1 vector [X, Y, Z, clock offset] in ECEF (meters, meters)
    %   wgs84_coord: 3x1 vector [longitude, latitude, altitude] in WGS84 (deg, deg, meters)

    % Constants
    c = 299792458; % Speed of light (m/s)
    tolerance = 1e-6; % Convergence tolerance (meters)
    maxIterations = 10; % Maximum iterations

    % Validate input files
    if ~exist(navFile, 'file') || ~exist(obsFile, 'file')
        error('Input file(s) not found: %s or %s', navFile, obsFile);
    end

    % Read navigation and observation data
    fprintf('Reading observation data...\n');
    try
        Nav = readNavData(navFile);
        [Obs, Approx_X, Approx_Y, Approx_Z, ~] = readObsData(obsFile);
    catch err
        error('Error reading RINEX files: %s', err.message);
    end

    % Validate input data
    if isempty(Nav) || isempty(Obs)
        error('Navigation or observation data is empty.');
    end
    if any(isnan([Approx_X, Approx_Y, Approx_Z]))
        error('Invalid approximate coordinates: NaN detected.');
    end

    % Initialize position iteration
    RxClockError = 1e-6; % Initial receiver clock error (seconds)
    iteration = 0;
    dx = [0.01; 0.01; 0.01; RxClockError * c]; % Initial position/clock offset
    Approximate_Coor = [Approx_X; Approx_Y; Approx_Z; RxClockError * c]; % Initial coordinates
    elevationMaskApplied = false;

    % Pre-allocate arrays
    nObs = length(Obs);
    GPS = zeros(nObs, 3); % Satellite positions
    GPS_Coordinate = zeros(nObs, 3); % Corrected satellite positions
    SxClockError = zeros(nObs, 1); % Satellite clock errors
    rho = zeros(nObs, 1); % Pseudoranges
    validSatellites = false(nObs, 1); % Valid satellite flags

    % Iteration loop
    while (norm(dx(1:3)) > tolerance && iteration < maxIterations) % Convergence check (position only)
        iteration = iteration + 1;
        fprintf('Iteration: %d\n', iteration);

        % Initialize measurement matrices
        B = zeros(nObs, 4); % Pre-allocate measurement matrix
        f = zeros(nObs, 1); % Pre-allocate residual vector
        observationsUsed = 0; % Count of valid satellites
        skippedSatellites = 0;

        for i = 1:nObs
            PRN = Obs(i).PRN;
            navIndex = find([Nav.PRN] == PRN);

            if isempty(navIndex)
                fprintf('  Warning: No nav data for PRN %d at time %.3f. Skipping.\n', PRN, Obs(i).Time_in_GPS);
                skippedSatellites = skippedSatellites + 1;
                continue;
            end

            % Find closest navigation epoch
            [~, closestIndex] = min(abs([Nav(navIndex).Time_in_GPS] - Obs(i).Time_in_GPS));
            Sate_Row = navIndex(closestIndex);

            % Compute satellite position
            GPS(i,:) = computeSatellitePosition(Nav, Sate_Row, Obs(i), RxClockError);
            if any(isnan(GPS(i,:)))
                fprintf('  Warning: Invalid satellite position for PRN %d. Skipping.\n', PRN);
                skippedSatellites = skippedSatellites + 1;
                continue;
            end

            % Calculate elevation angle
            [elevation, ~] = calculateElevationAzimuth(Approximate_Coor(1:3), GPS(i,:));

            % Apply elevation mask after 3 iterations
            if iteration >= 3 && elevation < elevationCutoff
                %fprintf('  Skipping PRN %d due to low elevation (%.2f < %.2f deg).\n', PRN, elevation, elevationCutoff);
                skippedSatellites = skippedSatellites + 1;
                continue;
            end

            % Apply corrections (pass scalar coordinates)
            try
                [GPS_Coordinate(i,:), SxClockError(i)] = applyCorrections(GPS(i,:), Obs(i), Nav(Sate_Row), ...
                    RxClockError, Approximate_Coor(1), Approximate_Coor(2), Approximate_Coor(3), ...
                    Nav(Sate_Row).ionAlpha, Nav(Sate_Row).ionBeta);
            catch err
                fprintf('  Warning: Error in applyCorrections for PRN %d: %s. Skipping.\n', PRN, err.message);
                skippedSatellites = skippedSatellites + 1;
                continue;
            end

            % Compute receiver position components
            [rho(i), Bi, fi] = computeReceiverPosition(GPS_Coordinate(i,:), Approximate_Coor, Obs(i), SxClockError(i));
            if any(isnan([Bi, fi]))
                fprintf('  Warning: Invalid measurement for PRN %d. Skipping.\n', PRN);
                skippedSatellites = skippedSatellites + 1;
                continue;
            end

            % Store valid observation
            observationsUsed = observationsUsed + 1;
            B(observationsUsed, :) = Bi;
            f(observationsUsed) = fi;
            validSatellites(i) = true;
        end

        % Trim matrices to valid observations
        B = B(1:observationsUsed, :);
        f = f(1:observationsUsed);

        % Check for sufficient satellites
        if observationsUsed < 4
            fprintf('  Error: Insufficient satellites (%d < 4, Skipped: %d).\n', observationsUsed, skippedSatellites);
            GPS_Receiver = NaN(4,1);
            wgs84_coord = NaN(3,1);
            return;
        end

        % Compute correction to receiver position/clock
        try
            dx = (B' * B) \ (B' * f); % Solve normal equations
        catch err
            fprintf('  Error: Singular matrix in least-squares solution: %s.\n', err.message);
            GPS_Receiver = NaN(4,1);
            wgs84_coord = NaN(3,1);
            return;
        end
        Approximate_Coor = Approximate_Coor + dx;
        RxClockError = Approximate_Coor(4) / c;

        % Log iteration details
        fprintf('  Position change: %.4f %.4f %.4f m, Clock change: %.4e s\n', dx(1:3), dx(4)/c);
        fprintf('  Approximate Coordinates: %.2f %.2f %.2f m, %.2f m\n', Approximate_Coor);
        fprintf('  Satellites used: %d, Skipped: %d\n', observationsUsed, skippedSatellites);

        % Apply elevation mask flag after iteration 3
        if iteration == 3 && ~elevationMaskApplied
            elevationMaskApplied = true;
            %fprintf('  Elevation mask applied (cutoff: %.2f deg).\n', elevationCutoff);
        end
    end

    % Check convergence
    if iteration >= maxIterations
        fprintf('  Warning: Did not converge within %d iterations (final position change: %.2e m).\n', ...
            maxIterations, norm(dx(1:3)));
    else
        fprintf('  Converged in %d iterations (position change: %.2e m).\n', iteration, norm(dx(1:3)));
    end

    % Store receiver position
    GPS_Receiver = Approximate_Coor;
    fprintf('ECEF Position: X=%.5f, Y=%.5f, Z=%.5f m\n', GPS_Receiver(1:3));

    % Convert to WGS84
    try
        wgs84_coord = convertECEFtoWGS84(GPS_Receiver(1), GPS_Receiver(2), GPS_Receiver(3));
    catch err
        fprintf('  Error converting to WGS84: %s\n', err.message);
        wgs84_coord = NaN(3,1);
        return;
    end

    % Validate WGS84 coordinates
    if any(isnan(wgs84_coord)) || wgs84_coord(1) < -180 || wgs84_coord(1) > 180 || ...
       wgs84_coord(2) < -90 || wgs84_coord(2) > 90
        fprintf('  Warning: Invalid WGS84 coordinates: Lon=%.8f, Lat=%.8f, Alt=%.3f\n', wgs84_coord);
        wgs84_coord = NaN(3,1);
        return;
    end

    fprintf('WGS84 Position: Lon=%.8f deg, Lat=%.8f deg, Alt=%.3f m\n', wgs84_coord);

    % Plot WGS84 position
    try
        plotWGS84Position(wgs84_coord);
    catch err
        fprintf('  Warning: Error plotting WGS84 position: %s\n', err.message);
    end
end