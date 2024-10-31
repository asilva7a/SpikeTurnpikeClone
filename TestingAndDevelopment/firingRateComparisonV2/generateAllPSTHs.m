function [cellDataStruct] = generateAllPSTHs(cellDataStruct, dataFolder)
    % Loop over all groups, recordings, and units in the structure
    groupNames = fieldnames(cellDataStruct);  % Extract group names

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

                % Extract the unit's data and generate PSTH
                try
                    [fullPSTH, binEdges, splitData, cellDataStruct] = ...
                        generatePSTH(cellDataStruct, groupName, recordingName, unitID);
                catch ME
                    % Handle any errors gracefully
                    warning('Error processing %s: %s', unitID, ME.message);
                end
            end
        end
    end

    % Save the updated struct to the specified data file path
    try
        save(dataFolder, 'cellDataStruct', '-v7');
        fprintf('Struct saved successfully to: %s\n', dataFolder);
    catch ME
        fprintf('Error saving the file: %s\n', ME.message);
    end
end

%% Helper Function: Generate PSTH for a Single Unit
function [fullPSTH, binEdges, splitData, cellDataStruct] = ...
    generatePSTH(cellDataStruct, groupName, recordingName, unitID)

    % Extract unit data
    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
    fprintf('Extracted data for Unit: %s\n', unitID);

    % Extract and normalize spike times
    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;

    % Check if spike times are empty
    if isempty(spikeTimes)
        warning('Spike times are empty for Unit: %s', unitID);
    end

    % Set binning parameters
    recordingLength = unitData.RecordingDuration;
    binWidth = unitData.binWidth;    

    % Validate bin width
    if binWidth <= 0 || binWidth > recordingLength
        error('Invalid bin width for Unit: %s', unitID);
    end

    % Calculate bin edges
    binEdges = edgeCalculator(spikeTimes, binWidth);

    % Split spike data into bins
    numBins = length(binEdges) - 1;
    splitData = cell(1, numBins);  % Preallocate cell array

    for i = 1:numBins
        binStart = binEdges(i);
        binEnd = binEdges(i + 1);
        splitData{i} = spikeTimes(spikeTimes >= binStart & spikeTimes < binEnd);

    end

    % Calculate PSTH
    spikeCounts = cellfun(@length, splitData);
    fullPSTH = spikeCounts / binWidth;  % Convert to firing rate

    % Save results to the unit's struct
    cellDataStruct.(groupName).(recordingName).(unitID).psthRaw = fullPSTH;
    cellDataStruct.(groupName).(recordingName).(unitID).binEdges = binEdges;
    cellDataStruct.(groupName).(recordingName).(unitID).numBins = numBins;

end

%% Helper Function: Calculate Bin Edges
function edges = edgeCalculator(spikeTimes, binWidth)
    % Define the start and stop times based on the actual range of spike times
    start = min(spikeTimes);
    stop = max(spikeTimes);

    % Calculate bin edges from start to stop with the specified bin width
    edges = start:binWidth:(stop + binWidth);  % Add extra bin width to include final spike

    % Optional: Display binning range for debugging
    fprintf('Generated bin edges from %.2f s to %.2f s with bin width %.2f s.\n', ...
            start, stop, binWidth);

end
