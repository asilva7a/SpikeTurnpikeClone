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

                % Extract the unit's data and generate PSTH with split data
                try
                    % Use a local copy of the unit's struct for efficiency
                    localUnitData = cellDataStruct.(groupName).(recordingName).(unitID);

                    % Generate PSTH and split data for the unit
                    [fullPSTH, binEdges, splitData] = generatePSTH(localUnitData);

                    % Save results to localUnitData and update the struct
                    localUnitData.psthRaw = single(fullPSTH);         % Convert to single precision to save memory
                    localUnitData.binEdges = single(binEdges);        % Convert to single precision
                    localUnitData.splitData = splitData;              % Store split spike times if needed
                    localUnitData.numBins = length(binEdges) - 1;     % Store number of bins

                    % Update main struct with local data
                    cellDataStruct.(groupName).(recordingName).(unitID) = localUnitData;

                    % Clear temporary variables to free memory
                    clear localUnitData fullPSTH binEdges splitData;

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
function [fullPSTH, binEdges, splitData] = generatePSTH(unitData)
    % Extract spike times and convert to seconds
    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;

    % Set binning parameters
    recordingLength = 5400; % Fixed recording duration in seconds
    binWidth = unitData.binWidth;

    % Validate bin width
    if binWidth <= 0 || binWidth > recordingLength
        error('Invalid bin width for Unit.');
    end

    % Calculate bin edges
    binEdges = single(0:binWidth:recordingLength);  % Convert to single precision

    % Split spike data into bins
    numBins = length(binEdges) - 1;
    splitData = cell(1, numBins);

    for i = 1:numBins
        binStart = binEdges(i);
        binEnd = binEdges(i + 1);
        % Assign spikes to the current bin
        splitData{i} = spikeTimes(spikeTimes >= binStart & spikeTimes < binEnd);
    end

    % Calculate spike count and convert to firing rate (PSTH)
    spikeCounts = cellfun(@length, splitData);
    fullPSTH = spikeCounts / binWidth;  % Convert to firing rate

    % Clear temporary variables to optimize memory usage
    clear spikeTimes spikeCounts;
end
