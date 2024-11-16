function cellDataStruct = generateAllPSTHs(cellDataStruct, paths, params)
    % Constants
    RECORDING_LENGTH = params.recordingPeriod;  % Use from params
    SAVE_INTERVAL = 100;      % units
    
    % Get first unit's binWidth and count total units
    [binWidth, totalUnits] = initializeParameters(cellDataStruct);
    if isempty(binWidth) || totalUnits == 0
        warning('Initialize:NoData', 'No valid data found for processing');
        return;
    end
    
    % Generate bin edges once
    binEdges = 0:binWidth:RECORDING_LENGTH;
    numBins = length(binEdges) - 1;
    
    % Process units
    processedUnits = 0;
    fprintf('Processing %d total units...\n', totalUnits);
    
    % Process each group
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Process units in current recording
            for u = 1:length(units)
                unitID = units{u};
                
                try
                    % Process unit
                    cellDataStruct.(groupName).(recordingName).(unitID) = ...
                        processUnit(cellDataStruct.(groupName).(recordingName).(unitID), ...
                                  binEdges, numBins);
                    
                    % Update and display progress
                    processedUnits = processedUnits + 1;
                    if mod(processedUnits, 10) == 0
                        fprintf('Processed %d/%d units (%.1f%%)\n', ...
                                processedUnits, totalUnits, ...
                                (processedUnits/totalUnits)*100);
                    end
                    
                    % Save intermediate results
                    if mod(processedUnits, SAVE_INTERVAL) == 0
                        saveIntermediateResults(cellDataStruct, paths.frTreatmentDir, processedUnits);
                    end
                    
                catch ME
                    warning('Process:UnitError', ...
                            'Error processing unit %s in %s/%s: %s', ...
                            unitID, groupName, recordingName, ME.message);
                end
            end
        end
    end
    
    % Final save
    if processedUnits > 0
        saveResults(cellDataStruct, paths.frTreatmentDir);
        fprintf('Processing complete: %d units processed\n', processedUnits);
    else
        warning('Process:NoUnitsProcessed', 'No units were successfully processed');
    end
end

function [binWidth, totalUnits] = initializeParameters(cellDataStruct)
    % Initialize outputs
    binWidth = [];
    totalUnits = 0;
    
    % Get first unit's binWidth
    groupNames = fieldnames(cellDataStruct);
    if isempty(groupNames)
        warning('Initialize:NoGroups', 'No groups found in cellDataStruct');
        return;
    end
    
    firstRecordings = fieldnames(cellDataStruct.(groupNames{1}));
    if isempty(firstRecordings)
        warning('Initialize:NoRecordings', 'No recordings found in group %s', groupNames{1});
        return;
    end
    
    firstUnits = fieldnames(cellDataStruct.(groupNames{1}).(firstRecordings{1}));
    if isempty(firstUnits)
        warning('Initialize:NoUnits', 'No units found in recording %s', firstRecordings{1});
        return;
    end
    
    % Get binWidth from first unit
    firstUnit = cellDataStruct.(groupNames{1}).(firstRecordings{1}).(firstUnits{1});
    if ~isfield(firstUnit, 'binWidth')
        warning('Initialize:NoBinWidth', 'No binWidth field in first unit');
        return;
    end
    binWidth = firstUnit.binWidth;
    
    % Count total units
    for g = 1:length(groupNames)
        recordings = fieldnames(cellDataStruct.(groupNames{g}));
        for r = 1:length(recordings)
            totalUnits = totalUnits + length(fieldnames(cellDataStruct.(groupNames{g}).(recordings{r})));
        end
    end
end

function unitData = processUnit(unitData, binEdges, numBins)
    % Check required fields
    if ~isfield(unitData, 'SpikeTimesall') || ~isfield(unitData, 'SamplingFrequency')
        warning('Process:MissingFields', 'Required fields missing for unit processing');
        return;
    end
    
    % Extract and normalize spike times
    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;
    
    if isempty(spikeTimes)
        warning('Process:EmptySpikes', 'No spike times found in unit data');
        fullPSTH = zeros(1, numBins);
    else
        % Use histcounts for binning
        [spikeCounts, ~] = histcounts(spikeTimes, binEdges);
        fullPSTH = spikeCounts / unitData.binWidth;
    end
    
    % Update unit data
    unitData.psthRaw = fullPSTH;
    unitData.binEdges = binEdges;
    unitData.numBins = numBins;
end

function saveIntermediateResults(cellDataStruct, frTreatmentDir, processedUnits)
    try
        backupFile = fullfile(frTreatmentDir, sprintf('cellDataStruct_backup_%d.mat', processedUnits));
        save(backupFile, 'cellDataStruct', '-v7.3', '-nocompression');
        fprintf('Saved backup after %d units\n', processedUnits);
    catch ME
        warning('Save:BackupFailed', 'Failed to save backup: %s', ME.message);
    end
end

function saveResults(cellDataStruct, frTreatmentDir)
    try
        save(fullfile(frTreatmentDir, 'cellDataStruct.mat'), 'cellDataStruct', '-v7.3', '-nocompression');
        fprintf('Final save completed\n');
    catch ME
        warning('Save:FinalFailed', 'Error saving final results: %s', ME.message);
    end
end
