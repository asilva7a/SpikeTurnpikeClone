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

%% Start parallel pool with a limited number of workers
if isempty(gcp('nocreate'))
    parpool('local', 2);  % Adjust to limit memory usage (e.g., 2 workers)
end

%% Parallel loop over groups and recordings
parfor ii = 1:numGroups
    groupDir = groupfoldernames{ii};
    groupInfo = dir(groupDir);
    groupInfo(~[groupInfo.isdir]) = [];
    groupInfo(ismember({groupInfo.name}, {'.', '..'})) = [];
    recfoldernames = fullfile(groupDir, {groupInfo.name});

    % Iterate over recordings in each group
    for jj = 1:length(recfoldernames)
        recDir = recfoldernames{jj};
        fprintf('Processing %s\n', recDir);

        % Setup directories
        MUA_Directory = fullfile(recDir, "MUA");
        MUA_allData_Directory = fullfile(MUA_Directory, "allData/");
        if ~exist(MUA_Directory, 'dir'), mkdir(MUA_Directory); end
        if ~exist(MUA_allData_Directory, 'dir'), mkdir(MUA_allData_Directory); end

        % Skip if downsampled file already exists
        downsampledFile = fullfile(MUA_allData_Directory, 'downsampledData.mat');
        if isfile(downsampledFile)
            fprintf('Skipping %s, downsampled data already exists.\n', recDir);
            continue;
        end

        % Find NSx file for this recording
        NSx_file = dir(fullfile(recDir, '*.ns6'));
        if isempty(NSx_file)
            warning('No NS6 file found for %s. Skipping...\n', recDir);
            continue;
        end
        NSx_filepath = fullfile(recDir, NSx_file.name);

        % Process the NSx file in chunks to avoid memory overload
        fprintf('Starting chunked processing for %s...\n', recDir);
        downsampledData = process_nsx_in_chunks(NSx_filepath, 3);

        % Save the result asynchronously with parfeval
        f = parfeval(@save_data_async, 0, downsampledFile, downsampledData);
        fprintf('Saving started asynchronously for %s.\n', recDir);

        % Optional: Monitor and wait for the save to complete
        wait(f);
        fprintf('Save completed for %s.\n', recDir);
    end
end

%% Chunked NSx Processing Function
function downsampledData = process_nsx_in_chunks(filepath, factor)
    % Map the NSx file to avoid loading everything into memory
    mappedFile = memmapfile(filepath, 'Format', 'int16');
    totalSamples = numel(mappedFile.Data);

    chunkSize = 1e6;  % Number of samples per chunk (adjust as needed)
    numChunks = ceil(totalSamples / chunkSize);

    % Preallocate downsampled data
    downsampledData = [];

    for i = 1:numChunks
        % Compute the range for this chunk
        startIdx = (i - 1) * chunkSize + 1;
        endIdx = min(i * chunkSize, totalSamples);

        % Load the chunk into memory
        dataChunk = mappedFile.Data(startIdx:endIdx);

        % Ensure the chunk size is divisible by 'factor'
        extraElements = mod(numel(dataChunk), factor);
        if extraElements > 0
            % Pad with zeros to make it divisible
            padding = zeros(factor - extraElements, 1, 'like', dataChunk);
            dataChunk = [dataChunk; padding];
        end

        % Downsample by taking the median of every 'factor' samples
        chunkDownsampled = median(reshape(dataChunk, factor, []), 1);

        % Append the downsampled chunk to the result
        downsampledData = [downsampledData, chunkDownsampled];  %#ok<AGROW>
    end
end

%% Asynchronous Save Function
function save_data_async(outputFile, data)
    % Save data asynchronously to a MAT file
    save(outputFile, 'data', '-v7.3');
end