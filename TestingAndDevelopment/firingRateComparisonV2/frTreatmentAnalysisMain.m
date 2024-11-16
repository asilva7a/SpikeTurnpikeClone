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
% % projectFolder/
% ├── SpikeStuff/
% │   ├── recordingDataFolder(s)
% │   └── all_data.mat
% └── frTreatmentAnalysis/
%     ├── config/
%     │   └── path_config_timestamp.mat
%     ├── data/
%     │   ├── cellDataStruct.mat
%     │   └── cellDataStruct_backup_timestamp.mat
%     └── figures/   
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
% In main script
clear; clc;

try
    % Initialize analysis (get params and paths)
    [params, paths] = initializeAnalysis();
    
    % Load data
    fprintf('Loading data...\n');
    load(paths.dataFile, 'all_data');
    
    % Extract unit data
    fprintf('Extracting unit data...\n');
    cellDataStruct = extractUnitData(all_data, paths, params);
    clear all_data;  % Clear to save memory
    
    % Generate directory structure
    fprintf('Creating directory structure...\n');
    generateFigureDirectories(cellDataStruct, paths);

   catch ME
    fprintf('Error: %s\n', ME.message);
    fprintf('In: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    rethrow(ME);
end

%% Data Analysis

% Generate PTSH for each unit using param file
cellDataStruct = generateAllPSTHs(cellDataStruct, paths, params);

% Smooth PSTH with boxcar sliding window
cellDataStruct = smoothAllPSTHs(cellDataStruct, paths, params);

% Calculate pre- and post-treatment firing rate 
cellDataStruct = calculateFiringRate(cellDataStruct, paths, params);

% Determine unit response type (Wilcoxon-Rank)
cellDataStruct = determineResponseType(cellDataStruct, paths, params, ...
    'tagSparse', true, ...
    'preWindow', [0, 1800], ...
    'postWindow', [2000, 3800]);


% Detect Outliers in Response Groups (CV and 1.5*IQR of max firing rate)
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

% Plot Wave-forms
plotAllMeanWaveforms(cellDataStruct);

% Plot Time Series with aesthetic binning
% Do in Cmd Line


%% End of Script
disp('Script finished...');