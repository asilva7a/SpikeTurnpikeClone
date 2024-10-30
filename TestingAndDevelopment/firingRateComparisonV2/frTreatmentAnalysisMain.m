%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% To-Do
%   PSTH Plotting
%       [x] Loading data and selecting directories
%       [ ] Extract data to struct
%       [ ] Calculate raw PSTH for single unit
%       [ ] Plot raw PSTH for single unit
%       [ ] Smoothing PSTH with boxcar smoothing
%       [ ] Plot unit PSTH with smoothing
%   Curve Plotting
%       [ ] ...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

% analyze_units
% Main script for analysing the single unit data

disp('Starting main script...');

%% Get Default Directory for data

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

%% Define the Path for the Saved Struct
cellDataStructPath = fullfile(dataFolder, 'cellDataStruct.mat');

%% Check if cellDataStruct Already Exists
if ~isfile(cellDataStructPath)
    % Extract relevant fields from all_data struct and save them
    disp('Calling extractUnitData...');
    extractUnitData(all_data);  % Extract and save struct
else
    disp('Skipping extractUnitData. Struct already exists.');
end

%% Load and Display the Struct for Debugging
try
    load(cellDataStructPath, 'cellDataStruct');
    disp('Loaded cellDataStruct.mat successfully!');
    disp('Loaded cellDataStruct in detail:');
    disp(struct2table(cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314,"AsArray",true));  % Display as table
catch ME
    error('Error loading cellDataStruct.mat: %s', ME.message);
end

%% Analysis (to do)
generatePSTH(cellDataStruct);

% Generate unit PSTH




%% Plotting (to do)


 

