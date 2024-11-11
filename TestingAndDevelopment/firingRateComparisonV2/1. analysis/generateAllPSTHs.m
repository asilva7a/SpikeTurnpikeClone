function cellDataStruct = generateAllPSTHs(cellDataStruct, dataFolder)
    % Initialize progress tracking
    totalUnits = countTotalUnits(cellDataStruct);
    processedUnits = 0;
    
    % Process units in parallel if Parallel Computing Toolbox is available
    try
        poolobj = gcp('nocreate');
        if isempty(poolobj)
            parpool('local');
        end
        useParallel = true;
    catch
        useParallel = false;
        warning('Parallel Computing Toolbox not available. Using serial processing.');
    end
    
    % Main processing loop
    groupNames = fieldnames(cellDataStruct);
    
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Process units in parallel or serial
            if useParallel
                parfor u = 1:length(units)
                    [psth, edges, ~] = generatePSTH_optimized(cellDataStruct.(groupName).(recordingName).(units{u}));
                    % Store results
                    cellDataStruct.(groupName).(recordingName).(units{u}).psthRaw = psth;
                    cellDataStruct.(groupName).(recordingName).(units{u}).binEdges = edges;
                end
            else
                for u = 1:length(units)
                    [psth, edges, ~] = generatePSTH_optimized(cellDataStruct.(groupName).(recordingName).(units{u}));
                    cellDataStruct.(groupName).(recordingName).(units{u}).psthRaw = psth;
                    cellDataStruct.(groupName).(recordingName).(units{u}).binEdges = edges;
                end
            end
            
            % Update progress
            processedUnits = processedUnits + length(units);
            fprintf('Progress: %d/%d units processed (%.1f%%)\n', ...
                processedUnits, totalUnits, (processedUnits/totalUnits)*100);
        end
    end
    
    % Save results
    saveResults(cellDataStruct, dataFolder);
end

function [psth, binEdges, splitData] = generatePSTH_optimized(unitData)
    % Extract spike times and convert to seconds
    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;
    
    % Set parameters
    recordingLength = 5400;
    binWidth = unitData.binWidth;
    binEdges = 0:binWidth:recordingLength;
    
    % Use histcounts instead of cell-based binning (much faster)
    [spikeCounts, binEdges] = histcounts(spikeTimes, binEdges);
    psth = spikeCounts / binWidth;  % Convert to firing rate
    
    % Only compute splitData if needed
    if nargout > 2
        splitData = arrayfun(@(i) spikeTimes(spikeTimes >= binEdges(i) & ...
            spikeTimes < binEdges(i+1)), 1:length(binEdges)-1, 'UniformOutput', false);
    else
        splitData = [];
    end
end

function totalUnits = countTotalUnits(cellDataStruct)
    % Count total units for progress tracking
    totalUnits = 0;
    groups = fieldnames(cellDataStruct);
    for g = 1:length(groups)
        recordings = fieldnames(cellDataStruct.(groups{g}));
        for r = 1:length(recordings)
            totalUnits = totalUnits + length(fieldnames(cellDataStruct.(groups{g}).(recordings{r})));
        end
    end
end

function saveResults(cellDataStruct, dataFolder)
    try
        save(dataFolder, 'cellDataStruct', '-v7.3', '-nocompression');
        fprintf('Data saved successfully to: %s\n', dataFolder);
    catch ME
        fprintf('Error saving data: %s\n', ME.message);
    end
end
