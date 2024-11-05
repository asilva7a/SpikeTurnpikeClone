function cellDataStruct = generateAllPSTHs(cellDataStruct, dataFolder)
    % Loop over all groups, recordings, and units in the structure
    groupNames = fieldnames(cellDataStruct);

    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};

                % Display the unit being processed for debugging
                fprintf('Processing Group: %s | Recording: %s | Unit: %s\n', ...
                        groupName, recordingName, unitID);

                % Extract only the required unit data for temporary processing
                try
                    % Extract a temporary local copy for processing
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    % Generate PSTH and split data for the unit
                    [fullPSTH, binEdges, splitData] = generatePSTH(unitData);

                    % Save only the necessary results back to the main structure
                    cellDataStruct.(groupName).(recordingName).(unitID).psthRaw = fullPSTH;
                    cellDataStruct.(groupName).(recordingName).(unitID).binEdges = binEdges;
                    cellDataStruct.(groupName).(recordingName).(unitID).splitData = splitData;
                    cellDataStruct.(groupName).(recordingName).(unitID).numBins = length(binEdges) - 1;

                catch ME
                    % Handle any errors gracefully
                    warning('Error processing %s: %s', unitID, ME.message);
                end

                % Clear the local unitData copy to free memory
                clear unitData;
            end
        end
    end

    % Save the updated struct to the specified data file path
    try
        save(dataFolder, 'cellDataStruct', '-v7.3'); % Use -v7.3 for large structures
        fprintf('Struct saved successfully to: %s\n', dataFolder);
    catch ME
        fprintf('Error saving the file: %s\n', ME.message);
    end
end

%% Helper Function: Generate PSTH for a Single Unit
function [fullPSTH, binEdges, splitData] = generatePSTH(unitData)
    % Extract spike times and convert to seconds
    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;

    % Check if spike times are empty
    if isempty(spikeTimes)
        warning('Spike times are empty for Unit.');
        fullPSTH = [];
        binEdges = [];
        splitData = [];
        return;
    end

    % Set binning parameters
    recordingLength = 5400; % Fixed recording duration in seconds
    binWidth = unitData.binWidth;

    % Validate bin width
    if binWidth <= 0 || binWidth > recordingLength
        error('Invalid bin width for Unit.');
    end

    % Calculate bin edges and preallocate split data cell array
    binEdges = 0:binWidth:recordingLength;
    numBins = length(binEdges) - 1;
    splitData = cell(1, numBins);

    % Split spike data into bins directly
    for i = 1:numBins
        splitData{i} = spikeTimes(spikeTimes >= binEdges(i) & spikeTimes < binEdges(i + 1));
    end

    % Calculate spike counts for each bin and convert to firing rate (PSTH)
    spikeCounts = cellfun(@length, splitData);
    fullPSTH = spikeCounts / binWidth;  % Convert to firing rate

    % Clear temporary variables to optimize memory usage
    clear spikeTimes spikeCounts;
end

