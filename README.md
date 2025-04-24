# GPS Single Point Positioning

## Overview
This project involves processing GPS data using RINEX files to compute the position of a GPS receiver. The following steps outline how to convert RINEX files, compute satellite coordinates, and resolve the GPS receiver's coordinates.

## Requirements
- **MATLAB R2024a or above**
- **Map Toolbox** (for plotting maps; internet connection required)

## Steps

1. Convert RINEX File to RINEX 2.10
- **Load the RINEX file**: Use the provided `convert.m` tool to load the RINEX file.
- **Convert to RINEX 2.10**: The tool will convert the loaded RINEX file into the RINEX 2.10 format.
- **Retain only GPS observations**: Ensure that only GPS observation data is included in the output.
- **Output files**: Save the results as `.o` (observation) and `.n` (navigation) files.

2. Load the RINEX Navigation File
3. Load the RINEX Observation File

4. Compute Satellite Coordinates
- Use the navigation messages from the navigation file.
- Pair the satellite coordinates with the observation data.

5. Resolve GPS Receiver Coordinates
- Compute the GPS receiver's coordinates using the satellite coordinates and pseudorange data.

## Compilation
- Compile the project using the `main.m` file, which serves as the entry point for executing the positioning calculations.

## Remarks
- Ensure that all necessary files are in the correct format RINEX 2.10.
- If map plotting is required, verify that the Map Toolbox is installed and the internet is active.
