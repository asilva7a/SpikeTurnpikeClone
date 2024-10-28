% analyze_units.m
% Main script to organize analysis, plotting, and statistical tests.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER INPUT: Set Directory and Analysis Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Prompt the user to select a directory to save files
saveDir = uigetdir(pwd, 'Select Directory to Save Files');
if saveDir == 0
    error('No directory selected. Exiting script.');
end

% Set analysis parameters via user input dialogs
prompt = {'Enter bin size (seconds):', ...
          'Enter smoothing window (e.g., [1 1 1 1 1]):', ...
          'Enter reference event time (e.g., stimulus onset in sec):', ...
          'Enter pre-treatment period (seconds):', ...
          'Enter post-treatment period (seconds):'};
dlgtitle = 'Set Analysis Parameters';
dims = [1 50]; % Dialog dimensions

% Default values for the parameters
defaultParams = {'0.1', '[1 1 1 1 1]', '1860', '1800', '1800'};

% Get user input
userInput = inputdlg(prompt, dlgtitle, dims, defaultParams);

% Parse user input into the params struct
params = struct();
params.binSize = str2double(userInput{1});
params.smoothingWindow = str2num(userInput{2}); %#ok<ST2NM>
params.moment = str2double(userInput{3});
params.preTreatmentPeriod = str2double(userInput{4});
params.postTreatmentPeriod = str2double(userInput{5});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Data and Process Units
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the data
load('all_data.mat');  % Load your structured data

% Define the cell types to analyze
cell_types = {'RS', 'FS'};

% Label responsive units and retrieve response types and unit IDs
responsive_units_struct = store_unit_responses_struct(all_data, cell_types, params);


% Extract response types and unit IDs from the data table
responseTypeVec = data_table_FR.ResponseType;
unitIDs = data_table_FR.UnitID;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate and Plot PSTHs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Generate PSTHs for all units
psthData = generate_unit_PSTHs(data_table_FR, all_data, ...
                               binSize, moment, ...
                               preTreatmentPeriod, postTreatmentPeriod);

% Plot and save individual PSTHs to the selected directory
% plot_unit_PSTH_fun(psthData, moment, saveDir);

% Plot overlaid PSTHs for responsive vs. non-responsive units
plot_group_PSTH(psthData, smoothingWindow);

% Plot mean + SEM PSTHs for all units (no overlaid individual PSTHs)
plot_mean_sem_PSTH_fun(all_data);

% Generate percent change PSTHs (mean + SEM)
percent_change_PSTH_fun(all_data);

% Generate ranked heatmap of modulated units
plot_heatmap_fun(all_data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End of Script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

