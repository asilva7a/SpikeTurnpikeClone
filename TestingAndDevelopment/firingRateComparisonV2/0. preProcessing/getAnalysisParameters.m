function [analysisParams,outputArg2] = getAnalysisParameters(inputArg1,inputArg2)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here







%% Grant OG Function for inspiration
projectFolder = uigetdir('Select the project folder in which you want to analyze multiple groups');
projectFolder = fullfile(projectFolder,'SpikeStuff');

% big UI input window
prompts = {'Cell types set to use for classification (1 for cortical FS/RS, 2 for striatal):',...
          'Timestamps? (0 for none, 1 for whisker stim, 2 for LED stim)',...
          'Stimulation duration in milliseconds (only matters if you have timestamps):',...
          'Cutoff after stim onset to calculate FR (for whole duration, use the value above):'};
default_inputs = {'1', '0', '500', '500'};

user_inputs = inputdlg(prompts, 'User Params', 1, default_inputs);
cell_types_set = str2num(user_inputs{1});
timestamps_type = str2num(user_inputs{2});
stim_duration_ms = str2num(user_inputs{3});
stim_duration_samples = stim_duration_ms*30;
user_time_cutoff_ms = str2num(user_inputs{4});
