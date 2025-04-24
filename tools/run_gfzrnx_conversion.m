% run_gfzrnx_conversion.m
% Simple MATLAB script to run gfzrnx_2.1.12_win11_64.exe for RINEX file conversion
% Converts RINEX observation (.xxo) or navigation (.xxn) files to version 2.10 with GPS-only data

function run_gfzrnx_conversion(input_file, output_file)
    % Path to gfzrnx executable (edit this to your OS exe)
    gfzrnx_exe = 'gfzrnx_2.1.12_win11_64.exe';
    
    % Check if executable exists
    if ~exist(gfzrnx_exe, 'file')
        error('gfzrnx executable not found at %s.', gfzrnx_exe);
    end
    
    % Validate inputs
    if ~ischar(input_file) || isempty(input_file)
        error('Input file must be a non-empty string.');
    end
    if ~ischar(output_file) || isempty(output_file)
        error('Output file must be a non-empty string.');
    end
    
    % Check if input file exists
    if ~exist(input_file, 'file')
        error('Input file %s not found.', input_file);
    end
    
    % Construct the gfzrnx command
    cmd = sprintf('"%s" -finp "%s" -fout "%s" -vo 2.10 -satsys G', ...
                  gfzrnx_exe, input_file, output_file);
    
    % Execute the command
    [status, cmdout] = system(cmd);
    
    % Check execution status
    if status == 0
        fprintf('Conversion successful. Output file: %s\n', output_file);
    else
        fprintf('Error during conversion:\n%s\n', cmdout);
        error('gfzrnx conversion failed.');
    end