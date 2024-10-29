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

%% Get Default Directory for data and storage

% Define the folder and file name for all_data
dataFolder = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';
fileName = 'all_data.mat';
filePath = fullfile(dataFolder, fileName);

% Load the file
if exist(filePath, "file") == 2;
    load(filePath, 'all_data');
    disp('File loaded successfully!');
else
    error('File not found: %s', filePath);
end

% Define folder for saving 
saveFolder = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';

%% Get User Input for directory
% Prompt the user to select directory with all_data struct
    %dataDir = uigetdir(pwd, 'Select Directory to Save Files');
    %if dataDir == 0
        %error('No directory selected. Exiting script.');
    %end
% Prompt the user to select a directory to save files
    %saveDir = uigetdir(pwd, 'Select Directory to Save Files');
    %if saveDir == 0
        %error('No directory selected. Exiting script.');
    %end

%% Extract Unit Data Into Data Structure (in progress)

% Extract relevant fields from all_data struct
cellDataStruct = extractUnitData(all_data, saveFolder);

% Optional: Display struct for debugging
disp(cellDataStruct);

%% Analysis (to do)

%% Plotting (to do)
 

