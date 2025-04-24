function [Obs, Approx_X, Approx_Y, Approx_Z, Obs_Time_of_FirstObs] = readObsData(obsFile)
    % Read RINEX observation file
    ObsData = fopen(obsFile, 'r');
    fprintf('Processing GPS data...\n');

    % Find approximate position (XYZ)
    Read_Obs_Approx_XYZ_Line = fgetl(ObsData);
    while ischar(Read_Obs_Approx_XYZ_Line)
        if contains(Read_Obs_Approx_XYZ_Line, 'APPROX POSITION XYZ')
            break;
        end
        Read_Obs_Approx_XYZ_Line = fgetl(ObsData);
    end
    Approx_X = str2num(Read_Obs_Approx_XYZ_Line(2:14));
    Approx_Y = str2num(Read_Obs_Approx_XYZ_Line(16:28));
    Approx_Z = str2num(Read_Obs_Approx_XYZ_Line(30:42));

    % Find observation types
    Read_Obs_C_Line = fgetl(ObsData);
    while ischar(Read_Obs_C_Line)
        if contains(Read_Obs_C_Line, '# / TYPES OF OBSERV')
            break;
        end
        Read_Obs_C_Line = fgetl(ObsData);
    end
    No_of_TypesOfObservation = str2num(Read_Obs_C_Line(4:6));

    % Locate C1 observation
    for p = 1:No_of_TypesOfObservation
        Types_of_observation{p} = Read_Obs_C_Line(4+6*p:6+6*p);
    end
    IndexNo_C = find(contains(Types_of_observation, 'C1'));

    % Find time of first observation
    Read_ObsLine = fgetl(ObsData);
    while ischar(Read_ObsLine)
        if contains(Read_ObsLine, 'TIME OF FIRST OBS')
            Obs_Time_of_FirstObs = string(Read_ObsLine(5:6));
            break;
        end
        Read_ObsLine = fgetl(ObsData);
    end

    % Skip to end of header
    Read_ObsLine = fgetl(ObsData);
    while ischar(Read_ObsLine)
        if contains(Read_ObsLine, 'END OF HEADER')
            break;
        end
        Read_ObsLine = fgetl(ObsData);
    end

    % Read observation data
    Epoch_OBS = 0;
    while ischar(Read_ObsLine)
        Read_ObsLine = fgetl(ObsData);
        if (Read_ObsLine == -1)
            break;
        end
        % Parse observation time and satellites
        if isequal(string(Read_ObsLine(2:3)), Obs_Time_of_FirstObs)
            No_of_PRN = str2num(Read_ObsLine(31:32));
            for h = 1:No_of_PRN
                Obs(Epoch_OBS + h).PRN = str2num(Read_ObsLine(31+3*h:32+3*h));
                Obs(Epoch_OBS + h).Year = str2num(Read_ObsLine(1:3)) + 2000;
                Obs(Epoch_OBS + h).Month = str2num(Read_ObsLine(5:6));
                Obs(Epoch_OBS + h).Day = str2num(Read_ObsLine(7:9));
                Obs(Epoch_OBS + h).Hour = str2num(Read_ObsLine(11:12));
                Obs(Epoch_OBS + h).Minute = str2num(Read_ObsLine(14:15));
                Obs(Epoch_OBS + h).Second = str2num(Read_ObsLine(17:26));
                Obs(Epoch_OBS + h).Epoch_Flag = str2num(Read_ObsLine(28:29));
                Obs(Epoch_OBS + h).Date_numerical = datenum(Obs(Epoch_OBS + h).Year, Obs(Epoch_OBS + h).Month, Obs(Epoch_OBS + h).Day, Obs(Epoch_OBS + h).Hour, Obs(Epoch_OBS + h).Minute, Obs(Epoch_OBS + h).Second);
                No_of_weekday_In_Obs = weekday(Obs(Epoch_OBS + h).Date_numerical) - 1; % Start from Sunday
                Obs(Epoch_OBS + h).Time_in_GPS = No_of_weekday_In_Obs * 60 * 60 * 24 + Obs(Epoch_OBS + h).Hour * 60 * 60 + Obs(Epoch_OBS + h).Minute * 60 + Obs(Epoch_OBS + h).Second;
            end
            % Read C1 observation data
            for d = 1:No_of_PRN
                Read_ObsLine = fgetl(ObsData);
                Obs(Epoch_OBS + d).C1 = str2num(Read_ObsLine(2+16*(IndexNo_C-1):15+16*(IndexNo_C-1)));
                Read_ObsLine = fgetl(ObsData);
            end
            Epoch_OBS = Epoch_OBS + No_of_PRN;
        end
    end
    fclose(ObsData);
end
