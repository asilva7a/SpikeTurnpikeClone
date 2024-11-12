%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% To-Do
%   [x] standardize saving logic for figures to follow directory structure
%   [ ] make function or modify main script to create single param file for pipeline
%   [ ] change names for functions so purpose is more unambiguous
%   [ ] finalize figure naming convention
%   [ ] change dir structure so data and figures saved in 2 subfolders of
%       main project folder
%
%% Directory Structure
% /home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/
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


%% Set Up Directories
% Get User Input for Directories
try
    [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = loadDataAndPreparePaths(); % Generates file paths for the output variables and variables saves to config.mat
    load(dataFilePath, 'all_data');

    % Call the extract function with the user-specified save path
    cellDataStruct = extractUnitData(all_data, cellDataStructPath, 0.01);  % set binWidth in seconds

    fprintf('Data loaded and saved successfully!\n');
catch ME
    fprintf('An error occurred: %s\n', ME.message);
end

clear all_data;

% Generate Figure Directories
generateFigureDirectories(cellDataStruct, figureFolder);

%% Data Processing

% Generate PTSH for single unit
cellDataStruct = generateAllPSTHs(cellDataStruct, dataFolder);

% Generate PSTH with boxcar smoothing
cellDataStruct = smoothAllPSTHs(cellDataStruct, dataFolder, 20);

% Calculate pre- and post-treatment firing rate
cellDataStruct = calculateFiringRate(cellDataStruct);

% Determine Unit response
cellDataStruct = determineResponseType(cellDataStruct, 1860, ...
    60, dataFolder); % Set bin-width to 60s

% Filter unit data by group for outliers
cellDataStruct = flagOutliersInPooledData(cellDataStruct, 'both', ...
    false, dataFolder);

% Calculate PSTH percent change 
cellDataStruct = calculatePercentChangeMean(cellDataStruct, dataFolder);

%% Plotting 

% Plot Time Locked smoothed PSTHs (mean + std. error of the mean);
% recording level
plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
     'mean+sem', 'both', true);

% Plot Time Locked smoothed PSTHs (mean + individual traces); 
% recording level
plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
     'mean+individual', 'both', true);

% Plot Time Locked smoothed PSTHs for pooled data (mean + SEM); 
% group level
plotPooledMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+sem', 'both', true);

% Plot Time Locked smoothed PSTHs for indidividual units (mean + individual)
% group level
plotPooledMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+individual', 'both', true);

% Plot Time locked percent change PSTHs (mean + inidividual units)
% recording level
plotTimeLockedPercentChangeCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+individual', 'both', true);

% Plot Time locked percent change PSTHs (mean + sem)
% recording level
plotTimeLockedPercentChangeCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+sem');

% Plot Time locked percent change PSTHs Group (mean + individual units)
% group level
plotPooledPercentPSTHCombined(cellDataStruct, figureFolder, 1860, ... % Name too similar to other function; differentiate somehow
    'mean+individual');

% Plot Time locked percent change PSTHs Group (mean + sem)
% group level
plotPooledPercentPSTHCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+sem');


%% End of Script
disp('Script finished...');




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