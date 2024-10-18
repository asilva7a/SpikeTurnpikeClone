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
parfor ii = 1:numGroups  % Parallel loop over groups
    groupDir = groupfoldernames{ii};
    groupInfo = dir(groupDir);
    groupInfo(~[groupInfo.isdir]) = [];
    groupInfo(ismember({groupInfo.name}, {'.', '..'})) = [];
    recfoldernames = fullfile(groupDir, {groupInfo.name});

    % ---- Line 46: Inner 'for' loop iterating over recordings ----
    for jj = 1:length(recfoldernames)  % Process recordings serially within the group
        recDir = recfoldernames{jj};
        fprintf('Processing %s\n', recDir);

        % Setup directories
        MUA_Directory = fullfile(recDir, "MUA");
        MUA_allData_Directory = fullfile(MUA_Directory, "allData/");
        if ~exist(MUA_Directory, 'dir'), mkdir(MUA_Directory); end
        if ~exist(MUA_allData_Directory, 'dir'), mkdir(MUA_allData_Directory); end

        % ---- Save electrode order here ----
        electrodes_order = [14; 20; 16; 18; 1; 31; 3; 29; 5; 27; 7; 25; ...
                            9; 23; 11; 21; 13; 19; 15; 17; 12; 22; ...
                            10; 24; 8; 26; 6; 28; 4; 30; 2; 32];
        electrodesFile = fullfile(MUA_allData_Directory, 'electrodes_order.mat');
        if ~isfile(electrodesFile)
            save(electrodesFile, 'electrodes_order', '-v7.3');
            fprintf('Saved electrode order for %s\n', recDir);
        end

        % ---- Check if downsampled data exists ----
        downsampledFile = fullfile(MUA_allData_Directory, 'downsampledData.mat');
        if isfile(downsampledFile)
            fprintf('Skipping %s, downsampled data already exists.\n', recDir);
            continue;
        end

        % Find the NSx file for this recording
        NSx_file = dir(fullfile(recDir, '*.ns6'));
        if isempty(NSx_file)
            warning('No NS6 file found for %s. Skipping...\n', recDir);
            continue;
        end
        NSx_filepath = fullfile(recDir, NSx_file.name);

        % ---- Chunk-based processing to avoid memory overload ----
        fprintf('Starting chunked processing for %s...\n', recDir);
        downsampledData = process_nsx_in_chunks(NSx_filepath, 3);

        % ---- Asynchronous saving using parfeval ----
        f = parfeval(@save_data_async, 0, downsampledFile, downsampledData);
        fprintf('Saving started asynchronously for %s.\n', recDir);

        % Optional: Wait for the save to complete (synchronize)
        wait(f);
        fprintf('Save completed for %s.\n', recDir);
    end  % End of inner 'for' loop
end  % End of outer 'parfor' loop

%% Chunked NSx Processing Function
function downsampledData = process_nsx_in_chunks(filepath, factor)
    % Use memmapfile to map the NSx data without loading everything into memory
    mappedFile = memmapfile(filepath, 'Format', 'int16');  % Adjust format if needed
    totalSamples = numel(mappedFile.Data);
    
    chunkSize = 1e6;  % Process 1 million samples at a time (adjust as needed)
    numChunks = ceil(totalSamples / chunkSize);

    % Preallocate the downsampled data
    downsampledData = [];

    for i = 1:numChunks
        % Compute the range for this chunk
        startIdx = (i - 1) * chunkSize + 1;
        endIdx = min(i * chunkSize, totalSamples);

        % Load the chunk into memory
        dataChunk = mappedFile.Data(startIdx:endIdx);

        % Downsample the chunk by taking the median of every 'factor' samples
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

