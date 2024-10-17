clc; clear;

% Starting with the following project folder structure...
%
% project_folder/
% ├─ SpikeStuff/
% │  ├─ Group_1/
% │  │  ├─ Recording_1/
% │  │  │  ├─ Recording1.ns6
% │  │  │  ├─ Recording1.nev
% │  │  │  ├─ Recording1_timestamps.txt
% │  │  │  ├─ Recording1.ccf
% │  │  ├─ Recording_2/
% │  │  ├─ Recording_N/
% │  ├─ Group_2/
% ├─ LFP (Optional)/
%
% For each recording folder, this script will


%% Get user input for project folder
initial_start_directory = '/home/silva7a-local/Documents/MATLAB'; 
projectFolder = uigetdir(initial_start_directory, 'Select the project folder in which you want to analyze multiple groups');
projectFolder = fullfile(projectFolder,'SpikeStuff');

% Get group folders and remove non-directories
dinfo = dir(projectFolder);
dinfo(~[dinfo.isdir]) = [];
dinfo(ismember({dinfo.name}, {'.', '..'})) = [];
groupfoldernames = fullfile(projectFolder, {dinfo.name});
numGroups = length(groupfoldernames);

%% Start the parallel processing (or use a regular loop if debugging)
if isempty(gcp('nocreate'))
    parpool;  % Optional: Use parpool only if not running
end

%% Iterate through groups and recordings
parfor ii = 1:numGroups  % Replace with `for` if debugging
    groupDir = groupfoldernames{ii};

    % **Move this directory scan OUTSIDE the recording loop**:
    groupInfo = dir(groupDir);
    groupInfo(~[groupInfo.isdir]) = [];
    groupInfo(ismember({groupInfo.name}, {'.', '..'})) = [];
    
    % Collect recording folder names once
    recfoldernames = fullfile(groupDir, {groupInfo.name});
    numRecordings = length(recfoldernames); 

    for jj = 1:numRecordings %loop through the recordings within a group folder
        [~,this_recording] = fileparts(recfoldernames(jj));
        fprintf('    Loading data for recording %s\n',this_recording);

        recDir = recfoldernames{jj};

        %% If MUA folder and sub-folders within MUA does not already exist, create it and proceed
        MUA_Directory = fullfile(recDir,"MUA"); %path of the MUA directory 
        
        MUA_allData_Directory = fullfile(recDir,"MUA/allData/"); %path of the allData directory
        MUA_figures_Directory = fullfile(recDir,"MUA/figures/"); %path of the figures directory 
   

        if ~exist(MUA_Directory,'dir')
            fprintf('MUA directory does not exist --> creating the MUA directory for %s\n',this_recording);
            mkdir(MUA_Directory);
        else
            fprintf('WARNING: MUA directory already exists --> skipping %s\n',this_recording);
        end

        if ~exist(MUA_allData_Directory,'dir')
            fprintf('allData sub-directory does not exist --> creating the MUA directory for %s\n',this_recording);
            mkdir(MUA_allData_Directory)

            %% Open NSx file and write data to 
            NSx_file = dir(fullfile(recDir,'*.ns6'));
            NSx_filepath = fullfile(recDir, NSx_file.name); 
    
            %% Specify electrode order and save .mat file for later usage
            %{
                This is the electrode number before we reorder them based on the
                arrangement of electrodes on the cylindrical probe. Reorder the 
                electrodes based on the order provided and picking out particular 
                electrode sample.
            %}
        
            electrodes_order = [14; 20; 16; 18; 1;31; 3; 29; 5; 27; 7; 25; 9; 23;...
                                11; 21; 13; 19; 15; 17; 12; 22; 10; 24; 8; 26;...
                                   6; 28; 4; 30; 2; 32];
    
            % Save the electrodes_order for future use
            save(strcat(MUA_allData_Directory,...
            'electrodes_order.mat'), 'electrodes_order', '-v7.3');

            %% Downsampling Section.
            %{
                In this section, we will reduce the sampling frequency from 30kHz to 10
                kHz. Start a while loop to only record the median value from every
                group of 3 events/samples.
            %}
        
            % Define how many sample section we want to compute the median from.
            downsampling_factor = 3;
        
            % Run the "downsample_data_fun" to downsample the data from original data.
            
            if isfile(fullfile(MUA_Directory,'allData',"electrode_data_downsampled.mat"))
            fprintf("    Downsampled data file already exists, skipping...\n");
            else
            tic
            downsample_data_fun(downsampling_factor, NSx_filepath, MUA_Directory);
            toc
            fprintf("    Finished Data downsampling!\n")
            end

        else 
            fprintf('WARNING: allData sub-directory already exists --> skipping %s\n',this_recording);
        end

        if ~exist(MUA_figures_Directory,'dir')
            fprintf('figures sub-directory does not exist --> creating the MUA directory for %s\n',this_recording);
            mkdir(MUA_figures_Directory)
        else 
            fprintf('WARNING: figures sub-directory already exists --> skipping %s\n',this_recording);
        end
    end
end
