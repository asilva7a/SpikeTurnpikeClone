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
            
            % Create temporary arrays to store results
            numUnits = length(units);
            psthResults = cell(numUnits, 1);
            binEdgesResults = cell(numUnits, 1);
            
            % Process units in parallel or serial
            if useParallel
                parfor u = 1:numUnits
                    unitID = units{u};
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    % Generate PSTH for this unit
                    try
                        [psth, edges] = generatePSTH_single(unitData);
                        psthResults{u} = psth;
                        binEdgesResults{u} = edges;
                    catch ME
                        warning('Error processing unit %s: %s', unitID, ME.message);
                        psthResults{u} = [];
                        binEdgesResults{u} = [];
                    end
                end
            else
                for u = 1:numUnits
                    unitID = units{u};
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    % Generate PSTH for this unit
                    try
                        [psth, edges] = generatePSTH_single(unitData);
                        psthResults{u} = psth;
                        binEdgesResults{u} = edges;
                    catch ME
                        warning('Error processing unit %s: %s', unitID, ME.message);
                        psthResults{u} = [];
                        binEdgesResults{u} = [];
                    end
                end
            end
            
            % Store results back in the structure
            for u = 1:numUnits
                if ~isempty(psthResults{u})
                    unitID = units{u};
                    cellDataStruct.(groupName).(recordingName).(unitID).psthRaw = psthResults{u};
                    cellDataStruct.(groupName).(recordingName).(unitID).binEdges = binEdgesResults{u};
                end
            end
            
            % Update progress
            processedUnits = processedUnits + numUnits;
            fprintf('Progress: %d/%d units processed (%.1f%%)\n', ...
                processedUnits, totalUnits, (processedUnits/totalUnits)*100);
        end
    end
    
    % Save results
    if ~isempty(dataFolder)
        try
            save(fullfile(dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7.3');
            fprintf('Data saved successfully to: %s\n', dataFolder);
        catch ME
            fprintf('Error saving data: %s\n', ME.message);
        end
    end
end

function [psth, binEdges] = generatePSTH_single(unitData)
    % Extract spike times and convert to seconds
    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;
    
    % Set parameters
    recordingLength = 5400;
    binWidth = unitData.binWidth;
    binEdges = 0:binWidth:recordingLength;
    
    % Use histcounts for efficient binning
    [spikeCounts, binEdges] = histcounts(spikeTimes, binEdges);
    psth = spikeCounts / binWidth;  % Convert to firing rate
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

