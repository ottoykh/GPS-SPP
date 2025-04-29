% Before Run this main function code 
% The navigation and observation file MUST convert into RINEX2.10 format 
% Conversion code is available in the /tools folder, run the "convert.m" 
% Also Change the folder path, as well the default is relative pathing 

% Broadcast ephemeris
nav_file = "tools/hkcl110a.25n"; 

% Observation data
obs_file = "tools/hkcl110a.25o"; 

% Compute position
[ecef, wgs84] = computeGPSPosition(nav_file, obs_file);
