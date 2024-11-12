function cellDataStruct = generateAllPSTHs(cellDataStruct, dataFolder)
    % Calculate total units for progress tracking
    totalUnits = countTotalUnits(cellDataStruct);
    processedUnits = 0;
    
    % Generate bin edges once for all units
    recordingLength = 5400; % Fixed recording duration in seconds
    
    % Get binWidth from first unit (assuming all units have same binWidth)
    firstGroup = fieldnames(cellDataStruct);
    firstRecording = fieldnames(cellDataStruct.(firstGroup{1}));
    firstUnit = fieldnames(cellDataStruct.(firstGroup{1}).(firstRecording{1}));
    binWidth = cellDataStruct.(firstGroup{1}).(firstRecording{1}).(firstUnit{1}).binWidth;
    
    % Generate bin edges once
    binEdges = 0:binWidth:recordingLength;
    numBins = length(binEdges) - 1;
    
    % Pre-allocate histcounts parameters
    edges = binEdges; % Store edges for histcounts
    
    % Main processing loop
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                processedUnits = processedUnits + 1;
                
                % Display progress
                fprintf('Processing Unit %d/%d: %s | %s | %s\n', ...
                    processedUnits, totalUnits, groupName, recordingName, unitID);
                
                try
                    % Extract unit data
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    % Extract and normalize spike times
                    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;
                    
                    if isempty(spikeTimes)
                        warning('Spike times empty for Unit: %s', unitID);
                        fullPSTH = zeros(1, numBins);
                    else
                        % Use histcounts for faster binning
                        [spikeCounts, ~] = histcounts(spikeTimes, edges);
                        fullPSTH = spikeCounts / binWidth; % Convert to firing rate
                    end
                    
                    % Store results
                    cellDataStruct.(groupName).(recordingName).(unitID).psthRaw = fullPSTH;
                    cellDataStruct.(groupName).(recordingName).(unitID).binEdges = binEdges;
                    cellDataStruct.(groupName).(recordingName).(unitID).numBins = numBins;
                    
                catch ME
                    warning('Error processing %s: %s', unitID, ME.message);
                end
            end
            
            % Optional: Save intermediate results
            if mod(processedUnits, 100) == 0 % Save every 100 units
                saveIntermediateResults(cellDataStruct, dataFolder, processedUnits);
            end
        end
    end
    
    % Final save
    saveResults(cellDataStruct, dataFolder);
end

function totalUnits = countTotalUnits(cellDataStruct)
    totalUnits = 0;
    groups = fieldnames(cellDataStruct);
    for g = 1:length(groups)
        recordings = fieldnames(cellDataStruct.(groups{g}));
        for r = 1:length(recordings)
            totalUnits = totalUnits + length(fieldnames(cellDataStruct.(groups{g}).(recordings{r})));
        end
    end
end

function saveIntermediateResults(cellDataStruct, dataFolder, processedUnits)
    try
        backupFile = fullfile(dataFolder, sprintf('cellDataStruct_backup_%d.mat', processedUnits));
        save(backupFile, 'cellDataStruct', '-v7.3', '-nocompression');
        fprintf('Intermediate save completed: %d units processed\n', processedUnits);
    catch ME
        warning('Failed to save intermediate results: %s', ME.message);
    end
end

function saveResults(cellDataStruct, dataFolder)
    try
        save(fullfile(dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7.3', '-nocompression');
        fprintf('Final save completed successfully\n');
    catch ME
        fprintf('Error saving final results: %s\n', ME.message);
    end
end

