%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% To-Do
%   PSTH Plotting
%       [x] Loading data and selecting directories
%       [x] Extract data to struct
%       [x] Calculate raw PSTH for single unit
%       [x] Plot raw PSTH for single unit
%       [X] Fix data not being saved to struct
%       [X] Smoothing PSTH with boxcar smoothing
%       [X] Plot unit PSTH with smoothing
%   Curve Plotting
%       [ ] ...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

%%  Main script for analysing the single unit data

disp('Starting main script...');

%% Load the data into struct

% Define the folder and file name for all_data
dataFolder = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';
fileName = 'all_data.mat';
filePath = fullfile(dataFolder, fileName);

% Load the all_data file
if isfile(filePath)
    load(filePath, 'all_data');
    disp('File loaded successfully!');
else
    error('File not found: %s', filePath);
end

% Define the Path for the Saved Struct
cellDataStructPath = fullfile(dataFolder, 'cellDataStruct.mat');

% Check if cellDataStruct Already Exists
if ~isfile(cellDataStructPath)
    % Extract relevant fields from all_data struct and save them
    disp('Calling extractUnitData...');
    extractUnitData(all_data);  % Extract and save struct
else
    disp('Skipping extractUnitData. Struct already exists.');
end

% Load and Display the Struct for Debugging
try
    load(cellDataStructPath, 'cellDataStruct');
    disp('Loaded cellDataStruct.mat successfully!');
    disp('Loaded cellDataStruct in detail:');
    disp(struct2table(cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1,"AsArray",true));  % Display as table
catch ME
    error('Error loading cellDataStruct.mat: %s', ME.message);
end

%% Analysis

% Generate PTSH for single unit
[fullPSTH, binEdges, splitData, cellDataStruct] = generatePSTH(cellDataStruct);

% Generate PSTH with boxcar smoothing
[smoothedPSTH, cellDataStruct]= smoothPSTH(cellDataStruct);


%% Plotting 

% Plot raw PSTH
try
    plotPSTHRaw(binEdges, fullPSTH, 1860);  % Assuming plotPSTHRaw is available
catch ME
    warning('%s: %s', ME.identifier, ME.message);  % Include format specifier
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



