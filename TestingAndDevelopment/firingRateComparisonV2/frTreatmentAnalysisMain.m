%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% To-Do
    % PSTH Plotting
%       [x] Loading data and selecting directories
%       [ ] Extract data to struct
%       [ ] Calculate raw PSTH for single unit
%       [ ] Plot raw PSTH for single unit
%       [ ] Smoothing PSTH with boxcar smoothing
%       [ ] Plot unit PSTH with smoothing
%   % Curve Plotting
%       [ ] ...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%% Extract Unit Data Into Data Structure (in progress)

% Load data
load('all_data.mat')

% Extract relevant fields from all_data struct
extractUnitData(all_data);

%% Analysis (to do)

%% Plotting (to do)
 

