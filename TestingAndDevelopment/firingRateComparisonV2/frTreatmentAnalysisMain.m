%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% To-Do
%   Scale up to do:
%   [ ] Make main function a for loop
%   [ ] Change function calls to flex for struct 

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

% Main script for analysing the single unit data

disp('Starting main script...');

%% Get User Input for Directories

try
    [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = loadDataAndPreparePaths();
    load(dataFilePath, 'all_data');

    % Call the extract function with the user-specified save path
    cellDataStruct = extractUnitData(all_data, cellDataStructPath);

    fprintf('Data loaded and saved successfully!\n');
catch ME
    fprintf('An error occurred: %s\n', ME.message);
end

clear all_data;

%% Analysis

% Generate PTSH for single unit
[cellDataStruct] = generateAllPSTHs(cellDataStruct, dataFolder);

% Generate PSTH with boxcar smoothing
cellDataStruct = smoothAllPSTHs(cellDataStruct, dataFolder, 10);

%% Plotting 

% Plot raw PSTH
plotAllRawPSTHs(cellDataStruct, 1860, figureFolder);

% Plot smooth PSTH
plotAllSmoothedPSTHs(cellDataStruct, 1860, figureFolder); % Saves figures assuming raw PSTH was plotted first

% Plot line PSTHs
try
    [smoothedPlot, rawPlot] = plotPSTHLines(cellDataStruct, 1860); % Set treatment period (2nd arg) to 1860s
catch ME
    % Handle any errors gracefully and display the error message
    warning('%s: %s', ME.identifier, ME.message);
end



