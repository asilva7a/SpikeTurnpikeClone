function [cellDataStruct] = generateAllPSTHs(cellDataStruct)
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

                % Try to generate PSTH for the current unit
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

    % Save the updated struct to a file
    saveDir = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';
    savePath = fullfile(saveDir, 'cellDataStruct.mat');

    if isfile(savePath)
        disp('Overwriting existing file.');
        delete(savePath);  % Remove old file
    else
        disp('Saving new file.');
    end

    try
        save(savePath, 'cellDataStruct', '-v7');
        disp('Struct saved successfully.');
    catch ME
        warning('Error saving the file: %s', ME.message);
    end
end

%% Helper Function: Generate PSTH for a Single Unit
function [fullPSTH, binEdges, splitData, cellDataStruct] = ...
    generatePSTH(cellDataStruct, groupName, recordingName, unitID)

    % Extract unit data
    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
    fprintf('Extracted data for Unit: %s\n', unitID);

    % Check if essential fields are missing
    requiredFields = {'SpikeTimesall', 'SamplingFrequency', 'RecordingDuration', 'binWidth'};
    for i = 1:length(requiredFields)
        if ~isfield(unitData, requiredFields{i})
            warning('Missing field "%s" for Unit: %s. Skipping unit.', requiredFields{i}, unitID);
            return;  % Skip this unit if a required field is missing
        end
    end

    % Extract and normalize spike times
    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;

    % Check if spike times are empty
    if isempty(spikeTimes)
        warning('Spike times are empty for Unit: %s. Skipping PSTH generation.', unitID);
        fullPSTH = [];
        binEdges = [];
        splitData = [];
        return;
    end

    % Set binning parameters
    recordingLength = unitData.RecordingDuration;
    binWidth = unitData.binWidth;

    % Validate bin width
    if binWidth <= 0 || binWidth > recordingLength
        warning('Invalid bin width (%f) for Unit: %s. Skipping PSTH generation.', binWidth, unitID);
        fullPSTH = [];
        binEdges = [];
        splitData = [];
        return;
    end

    % Calculate bin edges
    binEdges = edgeCalculator(0, binWidth, recordingLength);

    % Split spike data into bins
    numBins = length(binEdges) - 1;
    splitData = cell(1, numBins);  % Preallocate cell array

    for i = 1:numBins
        binStart = binEdges(i);
        binEnd = binEdges(i + 1);
        splitData{i} = spikeTimes(spikeTimes >= binStart & spikeTimes < binEnd);

        % Warning if no spikes in a bin
        if isempty(splitData{i})
            warning('No spikes in Bin %d for Unit: %s.', i, unitID);
        end
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
function edges = edgeCalculator(start, binWidth, stop)
    % Generate bin edges with the specified width
    edges = start:binWidth:stop;

    % Check if edges are empty or invalid
    if isempty(edges)
        warning('Generated bin edges are empty. Check bin width or recording length.');
    end
end
