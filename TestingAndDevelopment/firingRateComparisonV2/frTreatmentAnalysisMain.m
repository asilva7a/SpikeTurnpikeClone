%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% To-Do
%   [x] standardize saving logic for figures to follow directory structure
%   [ ] plot avg smooth exp psth normalized to ctrl waveform
%   [ ] make function or modify main script to create single param file for pipeline
%   [ ] change names for functions so purpose is more unambiguous
%   [ ] finalize figure naming convention
%   [ ] change dir structure so data and figures saved in 2 subfolders of
%       main project folder
%   [ ] change back up generation for cellDataStruct to after struct is
%       generated and fully populated
%   [ ] go through file generation and make sure the naming convention is
%       consistent with data structure below
%
%% Directory Structure
% ProjectFolder:~/frTreatmentAnalysisMain_figureResults/binWith(#)boxCar(#)
% ├── projectData
% │   ├── all_data.mat
% │   ├── config.mat 
% │   └── cellDataStruct.mat
% └── projectFigures
%     ├── 0.expFigures (e.g. experimental, ctrl)
%     │   └── experimental_Figure-timestamp.fig
%     └── groupName (e.g. Ctrl, Emx, Pvalb)S
%         ├── 0.groupFigures
%         │   └── Emx_Figure-timestamp.fig           
%         └── recordingName (e.g emx_0001_rec1)
%             ├── 0.recordingFiguresS
%             │   └── emx_0001_rec1_Figure-timestamp.fig           
%             └── unitID (e.g. cid214)
%                 └── cid214_Figure-timestamp.fig
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
    [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = ...
    loadDataAndPreparePaths(); % Generates file paths for the output variables and variables saves to config.mat
    load(dataFilePath, 'all_data');

    % Call the extract function with the user-specified save path
    cellDataStruct = extractUnitData(all_data, cellDataStructPath, 1);  % set binWidth in seconds

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
cellDataStruct = smoothAllPSTHs(cellDataStruct, dataFolder, 10);

% Calculate pre- and post-treatment firing rate
cellDataStruct = calculateFiringRate(cellDataStruct);

% Determine Unit response
cellDataStruct = determineResponseType(cellDataStruct, 1860, ...
    1, dataFolder, true); % Set bin-width to 60s

% Detect Outliers in Response Groups
cellDataStruct = flagOutliersInPooledData(cellDataStruct, ...
    'multi', figureFolder, dataFolder);

% Calculate PSTH percent change 
cellDataStruct = calculatePercentChangeMean(cellDataStruct, dataFolder);

% Filter tagged units from remaining analysis
cellDataStruct = getCleanUnits(cellDataStruct);


%% Plotting 
% Plot Time Locked smoothed PSTHs (mean + std. error of the mean);
plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
     'mean+sem', 'single', true);

% Plot Time Locked smoothed PSTHs (mean + individual traces); 
plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
     'mean+individual', 'single', true);

% Plot Time Locked smoothed PSTHs for pooled data (mean+SEM); 
plotPooledMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+sem', 'single', true);

% Plot Time Locked smoothed PSTHs for indidividual units (mean+individual)
plotPooledMeanPSTHCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+individual', 'single', true);

% Plot Time locked percent change PSTHs (mean+individual units)
plotTimeLockedPercentChangeCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+individual', 'single', true);

% Plot Time locked percent change PSTHs (mean+sem)
plotTimeLockedPercentChangeCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+sem', 'single', true);

% Plot Time locked percent change PSTHs Group (mean+individual units)
plotPooledPercentPSTHCombined(cellDataStruct, figureFolder, 1860, ... % Name too similar to other function; differentiate somehow
    'mean+individual', 'single', true);

% Plot Time locked percent change PSTHs Group (mean+sem)
plotPooledPercentPSTHCombined(cellDataStruct, figureFolder, 1860, ...
    'mean+sem', 'single', true);

% Calculate Exp vs. Ctrl psthSmoothed stats
[expStats, ctrlStats] = calculatePooledBaselineVsPostStats(cellDataStruct);

    % Save statistics if needed
    save(fullfile(dataFolder, ...
        'pooledBaselineVsPostStats.mat'), 'expStats', 'ctrlStats');
    
    % Plot Pooled Unit PSTHs Exp and Ctrl
    plotPooledBaselineVsPost(expStats, ctrlStats, figureFolder);


% Calculate Exp vs. Ctrl %-change stats
[expStats, ctrlStats] = calculatePooledPercentChangeStats( ...
    cellDataStruct);

    % Save statistics if needed
    save(fullfile(dataFolder, ...
        'pooledPercentChangeStats.mat'), 'expStats', 'ctrlStats');

    % Plot Pooled Percent Change Exp and Ctrl
    plotPooledPercentChangeBaselineVsPost(expStats, ...
        ctrlStats, figureFolder);

%% End of Script
disp('Script finished...');