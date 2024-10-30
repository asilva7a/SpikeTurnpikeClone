%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% To-Do
%   Scale up to do:
%   [ ] Make main function a for loop
%   [ ] Change function calls to flex for struct 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

%%  Main script for analysing the single unit data

disp('Starting main script...');

%% Get User Input for Directories

try
    % Get user inputs for paths
    [dataFilePath, figureFolder] = getUserPaths();

    % Load the data file
    load(dataFilePath, 'all_data.mat');  % Adjust the variable name if needed

    % Display a confirmation message
    fprintf('Ready to save figures in: %s\n', figureFolder);

catch ME
    % If any error occurs, handle it gracefully
    fprintf('Failed to initialize paths: %s\n', ME.message);
end

%% Load the data into struct

% Default directory and file name
dataFolder = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';
fileName = 'all_data.mat';
filePath = fullfile(dataFolder, fileName);
defaultValues = {defaultFolder, defaultFile};  % Default inputs

% Get user input for directories
prompt = {'Enter Data Folder:', 'Enter File Name:'};
userInput = inputdlg(prompt, 'Select Data File', [1 50], defaultValues); 

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
disp('Calling extractUnitData...');
extractUnitData(all_data);  % Extract and save struct

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
[cellDataStruct] = generateAllPSTHs(cellDataStruct);

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



