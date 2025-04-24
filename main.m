% Before Run this main funtion code 
% The navigation and observation file MUST convert into RINEX2.10 format 
% Conversion code is avaliable in the /tools folder, run the "convert.m" 
% Also Change the folder path, as well the default is relative pathing 

% Broadcast ephemeris
nav_file = "tools/hcku2500.24n"; 

% Observation data
obs_file = "tools/hcku2500.24o"; 

% Compute position
[ecef, wgs84] = computeGPSPosition(nav_file, obs_file);