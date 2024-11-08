%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% To-Do
%

%% Directory Structure
% /home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testFigures/
% └── GroupName
%     └── RecordingName
%         ├── Raw PSTHs
%         │   ├── RawPSTH-cid0_2024-10-30_13-45.png
%         │   └── ...
%         └── Smoothed PSTHs
%             ├── SmoothedPSTH-cid0_2024-10-30_13-45.png
%             └── ...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

%%  Main script for analysing the single unit data

disp('Starting main script...');

% % Check for GPU availability
% useGPU = false;  % Default is not to use GPU
% if gpuDeviceCount > 0
%     disp('GPU detected! Enabling GPU acceleration for compatible functions.');
%     gpuDevice(1);  % Initialize the first GPU device
%     useGPU = true;
% else
%     disp('No GPU detected. Proceeding with CPU computation.');
% end


%% Get User Input for Directories

try
    [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = loadDataAndPreparePaths();
    load(dataFilePath, 'all_data');

    % Call the extract function with the user-specified save path
    cellDataStruct = extractUnitData(all_data, cellDataStructPath, 60);

    fprintf('Data loaded and saved successfully!\n');
catch ME
    fprintf('An error occurred: %s\n', ME.message);
end

clear all_data;

%% Data Processing

% Generate PTSH for single unit
cellDataStruct = generateAllPSTHs(cellDataStruct, dataFolder);

% Generate PSTH with boxcar smoothing
cellDataStruct = smoothAllPSTHs(cellDataStruct, dataFolder, 5);

% Calculate pre- and post-treatment firing rate
cellDataStruct = calculateFiringRate(cellDataStruct);

% Determine Unit response
cellDataStruct = determineResponseType(cellDataStruct, 1860, 0.1, dataFolder);

% Filter unit data by group for outliers
cellDataStruct = flagOutliersInPooledData(cellDataStruct, 'both', true);


%% Plotting 

% Plot Time Locked smoothed PSTHs (mean + std. error of the mean)
plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+sem');

% Plot Time Locked smoothed PSTHs (mean + individual traces)
plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+individual');

%% End of Script
disp('Script finished...');


%% Optional Plots

% Sanity Check for individual units
% plotResponseTypeSanityChecks(cellDataStruct, figureFolder);

%% Old Plotting Functions

% Plot raw PSTH
%plotAllRawPSTHs(cellDataStruct, 1860, figureFolder, dataFolder);

% Plot smooth PSTH
%plotAllSmoothedPSTHs(cellDataStruct, 1860, figureFolder); % Saves figures assuming raw PSTH was plotted first

% Plot line PSTHs
%plotPSTHLines(cellDataStruct, 1860, figureFolder, dataFolder); % Saves figures assuming raw PSTH was plotted first

% Plot average PSTHs with individual response
%plotAveragePSTHWithResponse(cellDataStruct, figureFolder);

% Plot group PSTHs with individual responses
% plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder);