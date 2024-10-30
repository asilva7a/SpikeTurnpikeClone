%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% To-Do
%   Scale up to do:
%   [ ] Make main function a for loop
%   [ ] Change function calls to flex for struct 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

% Main script for analysing the single unit data

disp('Starting main script...');

%% Get User Input for Directories

try
    [dataFilePath, cellDataStructPath, figureFolder] = loadDataAndPreparePaths();
    load(dataFilePath, 'all_data');

    % Call the extract function with the user-specified save path
    cellDataStruct = extractUnitData(all_data, cellDataStructPath);

    fprintf('Data loaded and saved successfully!\n');
catch ME
    fprintf('An error occurred: %s\n', ME.message);
end


%% Analysis

% Generate PTSH for single unit
[cellDataStruct] = generateAllPSTHs(cellDataStruct, dataFilePath);

% Generate PSTH with boxcar smoothing
cellDataStruct = smoothAllPSTHs(cellDataStruct, 10);

%% Plotting 
try
    % Ensure the input structure is not empty
    if isempty(cellDataStruct) || ~isstruct(cellDataStruct)
        error('PlotError:InvalidInput', 'Input cellDataStruct is empty or not a valid structure.');
    end

    % Ensure the required data is present in the structure
    validatePSTHData(cellDataStruct);

    % Call the function to plot all raw PSTHs with the specified treatment line
    plotAllRawPSTHs(cellDataStruct, 1860);
    fprintf('All raw PSTHs plotted successfully.\n');

catch ME
    % Log detailed error information including stack trace
    fprintf('Error in plotAllRawPSTHs:\nIdentifier: %s\nMessage: %s\n', ...
            ME.identifier, ME.message);

    % Print the error stack for more context
    for k = 1:length(ME.stack)
        fprintf('In %s (line %d)\n', ME.stack(k).file, ME.stack(k).line);
    end
end

% Plot smooth PSTH
try
    plotPSTHsmooth(binEdges, smoothedPSTH, 1860, 'Peri-Stimulus Time Histogram (PSTH) with Boxcar Smoothing');  % Assuming plotPSTHRaw is available
catch ME
    warning('%s: %s', ME.identifier, ME.message);  % Include format specifier
end

% Plot line PSTHs
try
    [smoothedPlot, rawPlot] = plotPSTHLines(cellDataStruct, 1860); % Set treatment period (2nd arg) to 1860s
catch ME
    % Handle any errors gracefully and display the error message
    warning('%s: %s', ME.identifier, ME.message);
end



