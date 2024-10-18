clc; clear;

%% Get user input for the project folder
initial_start_directory = '/home/silva7a-local/Documents/MATLAB';
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

% Pre-check for existing electrode order files and create them if needed
for ii = 1:numGroups
    groupDir = groupfoldernames{ii};
    groupInfo = dir(groupDir);
    groupInfo(~[groupInfo.isdir]) = [];
    groupInfo(ismember({groupInfo.name}, {'.', '..'})) = [];
    recfoldernames = fullfile(groupDir, {groupInfo.name});

    for jj = 1:length(recfoldernames)
        recDir = recfoldernames{jj};
        MUA_Directory = fullfile(recDir, "MUA");
        MUA_allData_Directory = fullfile(MUA_Directory, "allData/");
        if ~exist(MUA_Directory, 'dir'), mkdir(MUA_Directory); end
        if ~exist(MUA_allData_Directory, 'dir'), mkdir(MUA_allData_Directory); end

        % Save electrode order if it doesn't already exist
        electrodesFile = fullfile(MUA_allData_Directory, 'electrodes_order.mat');
        if ~isfile(electrodesFile)
            electrodes_order = [14; 20; 16; 18; 1; 31; 3; 29; 5; 27; ...
                                7; 25; 9; 23; 11; 21; 13; 19; 15; 17; ...
                                12; 22; 10; 24; 8; 26; 6; 28; 4; 30; 2; 32];
            save(electrodesFile, 'electrodes_order', '-v7.3');
            fprintf('Saved electrode order for %s\n', recDir);
        end
    end
end

% Preallocate struct array to store processed data and paths
results = struct('data', {}, 'path', {});

%% Parallel loop for data processing (no saves inside `parfor`)
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

        % Process the NSx file in chunks
        fprintf('Starting chunked processing for %s...\n', recDir);
        downsampledData = process_nsx_in_chunks(NSx_filepath, 3);

        % Store the result and path for later saving
        localResults = [localResults; struct('data', downsampledData, 'path', downsampledFile)];
    end

    % Store local results in the global results array
    results(ii).data = localResults;
end

%% Save all results sequentially after the `parfor` loop completes
for ii = 1:numGroups
    for jj = 1:length(results(ii).data)
        % Extract the downsampled data from the results struct
        downsampledData = results(ii).data(jj).data;

        % Save the downsampled data with the correct field name
        save(results(ii).data(jj).path, 'downsampledData', '-v7.3');

        fprintf('Saved downsampled data to %s\n', results(ii).data(jj).path);
    end
end

%% Chunked NSx Processing Function
function downsampledData = process_nsx_in_chunks(filepath, factor)
    mappedFile = memmapfile(filepath, 'Format', 'int16');
    totalSamples = numel(mappedFile.Data);

    chunkSize = 1e6;
    numChunks = ceil(totalSamples / chunkSize);

    downsampledData = [];
    for i = 1:numChunks
        startIdx = (i - 1) * chunkSize + 1;
        endIdx = min(i * chunkSize, totalSamples);

        dataChunk = mappedFile.Data(startIdx:endIdx);

        remainder = mod(numel(dataChunk), factor);
        if remainder > 0
            padding = zeros(factor - remainder, 1, 'like', dataChunk);
            dataChunk = [dataChunk; padding];
            fprintf('Padded chunk %d with %d zeros.\n', i, numel(padding));
        end

        chunkDownsampled = median(reshape(dataChunk, factor, []), 1);
        downsampledData = [downsampledData, chunkDownsampled];
    end
end

