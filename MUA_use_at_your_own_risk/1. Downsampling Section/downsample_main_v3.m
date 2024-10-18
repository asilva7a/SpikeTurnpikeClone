clc; clear;

%% Get user input for the project folder
initial_start_directory = '/home/cresp1el-local/Documents/MATLAB';
projectFolder = uigetdir(initial_start_directory, 'Select the project folder in which you want to analyze multiple groups');
projectFolder = fullfile(projectFolder, 'SpikeStuff');

% Collect group folder names
dinfo = dir(projectFolder);
dinfo(~[dinfo.isdir]) = [];
dinfo(ismember({dinfo.name}, {'.', '..'})) = [];
groupfoldernames = fullfile(projectFolder, {dinfo.name});
numGroups = length(groupfoldernames);

%% Preload all recording paths to avoid file I/O conflicts in `parfor`
recordingInfo = [];  % Struct to store file paths and directories

for ii = 1:numGroups
    groupDir = groupfoldernames{ii};
    groupInfo = dir(groupDir);
    groupInfo(~[groupInfo.isdir]) = [];
    groupInfo(ismember({groupInfo.name}, {'.', '..'})) = [];
    recfoldernames = fullfile(groupDir, {groupInfo.name});

    for jj = 1:length(recfoldernames)
        recDir = recfoldernames{jj};

        % Locate NSx files and prepare paths for saving
        NSx_file = dir(fullfile(recDir, '*.ns6'));
        if isempty(NSx_file), continue; end  % Skip if no NSx file found

        NSx_filepath = fullfile(recDir, NSx_file.name);
        MUA_Directory = fullfile(recDir, "MUA");
        MUA_allData_Directory = fullfile(MUA_Directory, "allData/");
        downsampledFile = fullfile(MUA_allData_Directory, 'electrode_data_downsampled.mat');

        % Store the paths in the struct
        recordingInfo(end+1) = struct( ...  %#ok<AGROW>
            'nsx_path', NSx_filepath, ...
            'save_path', downsampledFile, ...
            'recDir', recDir, ...
            'MUA_Directory', MUA_Directory, ...
            'MUA_allData_Directory', MUA_allData_Directory);
    end
end

%% Start parallel pool with limited workers
if isempty(gcp('nocreate'))
    parpool('local', 2);  % Adjust based on system memory
end

%% Process each recording in parallel
parfor idx = 1:length(recordingInfo)
    rec = recordingInfo(idx);

    % Skip if the downsampled file already exists
    if isfile(rec.save_path)
        fprintf('Skipping %s, downsampled data already exists.\n', rec.recDir);
        continue;
    end

    % Ensure directories exist
    if ~exist(rec.MUA_Directory, 'dir'), mkdir(rec.MUA_Directory); end
    if ~exist(rec.MUA_allData_Directory, 'dir'), mkdir(rec.MUA_allData_Directory); end

    % Process the NSx file and save the downsampled data
    try
        fprintf('Starting chunked processing for %s...\n', rec.recDir);
        downsampledData = process_nsx_in_chunks(rec.nsx_path, 3);

        % Save the downsampled data
        save(rec.save_path, 'electrode_data_downsampled', '-v7.3');
        fprintf('Saved downsampled data to %s\n', rec.save_path);

    catch ME
        fprintf('Error processing %s: %s\n', rec.recDir, ME.message);
    end
end

%% Chunked NSx Processing Function
function downsampledData = process_nsx_in_chunks(filepath, factor)
    % Use memmapfile to read the data efficiently
    mappedFile = memmapfile(filepath, 'Format', 'int16');
    totalSamples = numel(mappedFile.Data);

    % Ensure data can be divided by 32 channels
    numChannels = 32;
    samplesPerChannel = totalSamples / numChannels;
    if mod(samplesPerChannel, 1) ~= 0
        warning('Trimming extra samples to fit 32 channels.');
        samplesPerChannel = floor(samplesPerChannel);
        mappedFile.Data = mappedFile.Data(1:samplesPerChannel * numChannels);
    end

    % Reshape the data into [numChannels x samplesPerChannel]
    reshapedData = reshape(mappedFile.Data, numChannels, []);

    % Calculate the number of downsampled samples
    numDownsampledSamples = floor(samplesPerChannel / factor);
    downsampledData = zeros(numChannels, numDownsampledSamples, 'like', reshapedData);

    % Downsample each channel
    for ch = 1:numChannels
        channelData = reshapedData(ch, 1:factor * numDownsampledSamples);
        reshapedChannel = reshape(channelData, factor, []);
        downsampledData(ch, :) = median(reshapedChannel, 1);
    end
end
