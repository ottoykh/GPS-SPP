function Nav = readNavData(navFile)
    % Read RINEX navigation file
    NavData = fopen(navFile, 'r');
    if NavData == -1
        error('Cannot open navigation file: %s', navFile);
    end

    % Initialize Klobuchar coefficients
    ionAlpha = [0, 0, 0, 0]; % Default: zero coefficients
    ionBeta = [72000, 0, 0, 0]; % Default: minimum period

    % Read header and parse ION ALPHA and ION BETA
    Read_NavLine = fgetl(NavData);
    while ischar(Read_NavLine)
        if contains(Read_NavLine, 'ION ALPHA')
            % Debug: Print raw line
            fprintf('ION ALPHA line: %s\n', Read_NavLine);
            % Replace 'D' with 'E' for scientific notation
            line = strrep(Read_NavLine(5:end), 'D', 'E');
            try
                % Parse four exponential numbers
                values = sscanf(line, '%e %e %e %e');
                if length(values) == 4
                    ionAlpha = values';
                else
                    warning('Invalid ION ALPHA format; using default [0, 0, 0, 0]');
                    ionAlpha = [0, 0, 0, 0];
                end
            catch
                warning('Failed to parse ION ALPHA; using default [0, 0, 0, 0]');
                ionAlpha = [0, 0, 0, 0];
            end
        elseif contains(Read_NavLine, 'ION BETA')
            % Debug: Print raw line
            fprintf('ION BETA line: %s\n', Read_NavLine);
            % Replace 'D' with 'E' for scientific notation
            line = strrep(Read_NavLine(5:end), 'D', 'E');
            try
                values = sscanf(line, '%e %e %e %e');
                if length(values) == 4
                    ionBeta = values';
                else
                    warning('Invalid ION BETA format; using default [72000, 0, 0, 0]');
                    ionBeta = [72000, 0, 0, 0];
                end
            catch
                warning('Failed to parse ION BETA; using default [72000, 0, 0, 0]');
                ionBeta = [72000, 0, 0, 0];
            end
        elseif contains(Read_NavLine, 'END OF HEADER')
            break;
        end
        Read_NavLine = fgetl(NavData);
    end

    % Debug: Print parsed coefficients
    fprintf('Parsed ionAlpha: %s\n', mat2str(ionAlpha));
    fprintf('Parsed ionBeta: %s\n', mat2str(ionBeta));

    No_Epoch_Nav = 1;
    while ischar(Read_NavLine)
        Read_NavLine = fgetl(NavData);
        if (Read_NavLine == -1)
            No_Epoch_Nav = No_Epoch_Nav - 1;
            break;
        end

        % Parse orbit data - Block 1
        Nav(No_Epoch_Nav).PRN = str2num(Read_NavLine(1:2));
        Nav(No_Epoch_Nav).Year = str2num(Read_NavLine(4:5)) + 2000;
        Nav(No_Epoch_Nav).Month = str2num(Read_NavLine(7:8));
        Nav(No_Epoch_Nav).Day = str2num(Read_NavLine(10:11));
        Nav(No_Epoch_Nav).Hour = str2num(Read_NavLine(13:14));
        Nav(No_Epoch_Nav).Minute = str2num(Read_NavLine(16:17));
        Nav(No_Epoch_Nav).Second = str2num(Read_NavLine(18:22));
        Nav(No_Epoch_Nav).Date_Numerical = datenum(Nav(No_Epoch_Nav).Year, Nav(No_Epoch_Nav).Month, Nav(No_Epoch_Nav).Day, Nav(No_Epoch_Nav).Hour, Nav(No_Epoch_Nav).Minute, Nav(No_Epoch_Nav).Second);
        No_of_weekday_In_Nav = weekday(Nav(No_Epoch_Nav).Date_Numerical) - 1; % Start from Sunday
        Nav(No_Epoch_Nav).Time_in_GPS = No_of_weekday_In_Nav * 60 * 60 * 24 + Nav(No_Epoch_Nav).Hour * 60 * 60 + Nav(No_Epoch_Nav).Minute * 60 + Nav(No_Epoch_Nav).Second;
        Nav(No_Epoch_Nav).SV_Clock_Bias = str2num(Read_NavLine(23:41));
        Nav(No_Epoch_Nav).SV_Clock_drift = str2num(Read_NavLine(42:60));
        Nav(No_Epoch_Nav).SV_Clock_drift_rate = str2num(Read_NavLine(61:79));
        Nav(No_Epoch_Nav).ionAlpha = ionAlpha; % Store Klobuchar coefficients
        Nav(No_Epoch_Nav).ionBeta = ionBeta;
        Read_NavLine = fgetl(NavData);
        % Parse orbit data - Block 2
        Nav(No_Epoch_Nav).IODE = str2num(Read_NavLine(4:22));
        Nav(No_Epoch_Nav).Crs = str2num(Read_NavLine(23:41));
        Nav(No_Epoch_Nav).Delta_N = str2num(Read_NavLine(42:60));
        Nav(No_Epoch_Nav).M0 = str2num(Read_NavLine(61:79));
        Read_NavLine = fgetl(NavData);
        % Parse orbit data - Block 3
        Nav(No_Epoch_Nav).Cuc = str2num(Read_NavLine(4:22));
        Nav(No_Epoch_Nav).e = str2num(Read_NavLine(23:41));
        Nav(No_Epoch_Nav).Cus = str2num(Read_NavLine(42:60));
        Nav(No_Epoch_Nav).sqrt_a = str2num(Read_NavLine(61:79));
        Read_NavLine = fgetl(NavData);
        % Parse orbit data - Block 4
        Nav(No_Epoch_Nav).Toe_time = str2num(Read_NavLine(4:22));
        Nav(No_Epoch_Nav).Cic = str2num(Read_NavLine(23:41));
        Nav(No_Epoch_Nav).Omega_0 = str2num(Read_NavLine(42:60));
        Nav(No_Epoch_Nav).CIS = str2num(Read_NavLine(61:79));
        Read_NavLine = fgetl(NavData);
        % Parse orbit data - Block 5
        Nav(No_Epoch_Nav).i0 = str2num(Read_NavLine(4:22));
        Nav(No_Epoch_Nav).Crc = str2num(Read_NavLine(23:41));
        Nav(No_Epoch_Nav).Omega = str2num(Read_NavLine(42:60));
        Nav(No_Epoch_Nav).Omega_dot = str2num(Read_NavLine(61:79));
        Read_NavLine = fgetl(NavData);
        % Parse orbit data - Block 6
        Nav(No_Epoch_Nav).IDOT = str2num(Read_NavLine(4:22));
        Nav(No_Epoch_Nav).weekNO = str2num(Read_NavLine(42:60));
        Read_NavLine = fgetl(NavData);
        % Parse orbit data - Block 7
        Nav(No_Epoch_Nav).SV_accuracy = str2num(Read_NavLine(4:22));
        Nav(No_Epoch_Nav).SV_health = str2num(Read_NavLine(23:41));
        Nav(No_Epoch_Nav).TGD = str2num(Read_NavLine(42:60));
        Nav(No_Epoch_Nav).IODC = str2num(Read_NavLine(61:79));
        Read_NavLine = fgetl(NavData);
        % Parse orbit data - Block 8
        Nav(No_Epoch_Nav).Transmission_timeofMessage = str2num(Read_NavLine(4:22));

        No_Epoch_Nav = No_Epoch_Nav + 1;
    end
    fclose(NavData);
end