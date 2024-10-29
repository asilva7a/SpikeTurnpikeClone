% analyze_units
% Main script for analysing the single unit data

%% Get User Input for directory
% Prompt the user to select directory with all_data struct
    dataDir = uigetdir(pwd, 'Select Directory to Save Files');
    if dataDir == 0
        error('No directory selected. Exiting script.');
    end
% Prompt the user to select a directory to save files
    saveDir = uigetdir(pwd, 'Select Directory to Save Files');
    if saveDir == 0
        error('No directory selected. Exiting script.');
    end

% Load data
load('all_data.mat')