% The Conversion exe is default as the Window11, for other OS, modifies the
% code "run_gfzrnx_conversion.m" and change the exe file
% Also Change the folder path, as well the default is relative pathing 

% Observation data
input = 'Rinex3/hkqt110a.25o';
output = 'hkqt110a.25o';

% Conversion to RINEX2.10
run_gfzrnx_conversion(input, output);

% Broadcast ephemeris
input = 'Rinex3/hkqt110a.25n';
output = 'hkqt110a.25n';

% Conversion to RINEX2.10
run_gfzrnx_conversion(input, output);