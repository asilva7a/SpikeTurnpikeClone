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

%% Start parallel pool with limited workers
if isempty(gcp('nocreate'))
    parpool('local', 2);  % Adjust based on system memory
end

% Preallocate a struct array to store processed data and paths
results = struct('data', {}, 'path', {});

%% Parallel loop for data processing (optimized with `parfor`)
parfor ii = 1:numGroups
    groupDir = groupfoldernames{ii};
    groupInfo = dir(groupDir);
    groupInfo(~[groupInfo.isdir]) = [];
    groupInfo(ismember({groupInfo.name}, {'.', '..'})) = [];
    recfoldernames = fullfile(groupDir, {groupInfo.name});

    localResults = [];  % Store local results for each worker

    for jj = 1:length(recfoldernames)
        recDir = recfoldernames{jj};
        fprintf('Processing %s\n', recDir);

        % Locate the downsampled data file path
        MUA_Directory = fullfile(recDir, "MUA");
        MUA_allData_Directory = fullfile(MUA_Directory, "allData/");
        downsampledFile = fullfile(MUA_allData_Directory, 'electrode_data_downsampled.mat');

        % Skip if the downsampled file already exists
        if isfile(downsampledFile)
            fprintf('Skipping %s, downsampled data already exists.\n', recDir);
            continue;
        end

        % Locate the NSx file
        NSx_file = dir(fullfile(recDir, '*.ns6'));
        if isempty(NSx_file)
            warning('No NS6 file found for %s. Skipping...\n', recDir);
            continue;
        end
        NSx_filepath = fullfile(recDir, NSx_file.name);

        % Process the NSx file in chunks and reshape correctly
        fprintf('Starting chunked processing for %s...\n', recDir);
        downsampledData = process_nsx_in_chunks_optimized(NSx_filepath, 3);

        % Store the result and path for later saving
        localResults = [localResults; struct('data', downsampledData, 'path', downsampledFile)];
    end

    % Store local results in the global results array
    results(ii).data = localResults;
end

%% Save all results sequentially after the `parfor` loop completes
for ii = 1:numGroups
    for jj = 1:length(results(ii).data)
        % Extract the downsampled data
        electrode_data_downsampled = results(ii).data(jj).data;

        % Save the downsampled data with the correct field name
        save(results(ii).data(jj).path, 'electrode_data_downsampled', '-v7.3');

        fprintf('Saved downsampled data to %s\n', results(ii).data(jj).path);
    end
end

%% Optimized Chunked NSx Processing Function
function downsampledData = process_nsx_in_chunks_optimized(filepath, factor)
    % Use memmapfile to read the data efficiently
    mappedFile = memmapfile(filepath, 'Format', 'int16');
    totalSamples = numel(mappedFile.Data);

    % Ensure the data can be divided by 32 channels
    numChannels = 32;
    samplesPerChannel = totalSamples / numChannels;

    if mod(samplesPerChannel, 1) ~= 0
        error('Total samples are not divisible by 32 channels. Check the data.');
    end

    % Reshape the data into [numChannels x samplesPerChannel]
    reshapedData = reshape(mappedFile.Data, numChannels, []);

    % Calculate the number of downsampled samples
    numDownsampledSamples = floor(samplesPerChannel / factor);
    downsampledData = zeros(numChannels, numDownsampledSamples, 'like', reshapedData);

    % Downsample each channel
    parfor ch = 1:numChannels
        % Extract the channel's data and reshape for median calculation
        channelData = reshapedData(ch, 1:factor*numDownsampledSamples);
        reshapedChannel = reshape(channelData, factor, []);
        downsampledData(ch, :) = median(reshapedChannel, 1);
    end
end


