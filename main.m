% Before Run this main function code 
% The navigation and observation file MUST convert into RINEX2.10 format 
% Conversion code is available in the /tools folder, run the "convert.m" 
% Also Change the folder path, as well the default is relative pathing 

% Broadcast ephemeris
nav_file = "testing/site0900.01n"; 

% Observation data
obs_file = "testing/site0900.01o";

% Elevation mask (degrees) to reduce the multipath signal effect 
elevation_angle_cutoff = 0; % degree

% Compute position
[ecef, wgs84] = computeGPSPosition(nav_file, obs_file, elevation_angle_cutoff);
