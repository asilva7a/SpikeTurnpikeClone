function cellDataStruct = smoothAllPSTHs(cellDataStruct, dataFolder, windowSize)
    % Set defaults and validate inputs
    if nargin < 3 || isempty(windowSize)
        windowSize = 5;
    end
    
    % Constants
    SAVE_INTERVAL = 100; % Save backup every 100 units
    
    try
        % Pre-compute boxcar filter
        boxcar = ones(1, windowSize) / windowSize;
        
        % Count total units for progress tracking
        totalUnits = countTotalUnits(cellDataStruct);
        if totalUnits == 0
            warning('Smooth:NoUnits', 'No units found in data structure');
            return;
        end
        
        % Process units
        processedUnits = 0;
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
                    
                    try
                        % Get unit data
                        unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                        
                        % Check for raw PSTH
                        if ~isfield(unitData, 'psthRaw') || isempty(unitData.psthRaw)
                            warning('Smooth:NoPSTH', 'No raw PSTH found for unit %s in %s/%s', ...
                                    unitID, groupName, recordingName);
                            continue;
                        end
                        
                        % Apply smoothing
                        smoothedPSTH = conv(unitData.psthRaw, boxcar, 'same');
                        
                        % Update unit data
                        cellDataStruct.(groupName).(recordingName).(unitID).psthSmoothed = smoothedPSTH;
                        
                        % Display progress every 10 units
                        if mod(processedUnits, 10) == 0
                            fprintf('Processed %d/%d units (%.1f%%)\n', ...
                                    processedUnits, totalUnits, ...
                                    (processedUnits/totalUnits)*100);
                        end
                        
                        % Save intermediate results
                        if mod(processedUnits, SAVE_INTERVAL) == 0
                            saveIntermediateResults(cellDataStruct, dataFolder, processedUnits);
                        end
                        
                    catch ME
                        warning('Smooth:UnitError', ...
                                'Error processing unit %s in %s/%s: %s', ...
                                unitID, groupName, recordingName, ME.message);
                    end
                end
            end
        end
        
        % Final save
        if processedUnits > 0
            saveResults(cellDataStruct, dataFolder);
            fprintf('Processing complete: %d units processed\n', processedUnits);
        else
            warning('Smooth:NoProcessed', 'No units were successfully processed');
        end
        
    catch ME
        handleError(ME);
        rethrow(ME);
    end
end

function totalUnits = countTotalUnits(cellDataStruct)
    totalUnits = 0;
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        recordings = fieldnames(cellDataStruct.(groupNames{g}));
        for r = 1:length(recordings)
            totalUnits = totalUnits + length(fieldnames(cellDataStruct.(groupNames{g}).(recordings{r})));
        end
    end
end

function saveIntermediateResults(cellDataStruct, dataFolder, processedUnits)
    try
        backupFile = fullfile(dataFolder, sprintf('cellDataStruct_backup_%d.mat', processedUnits));
        save(backupFile, 'cellDataStruct', '-v7.3', '-nocompression');
        fprintf('Saved backup after %d units\n', processedUnits);
    catch ME
        warning('Save:BackupFailed', 'Failed to save backup: %s', ME.message);
    end
end

function saveResults(cellDataStruct, dataFolder)
    try
        save(fullfile(dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7.3', '-nocompression');
        fprintf('Final save completed\n');
    catch ME
        warning('Save:FinalFailed', 'Error saving final results: %s', ME.message);
    end
end

function handleError(ME)
    warning('Smooth:ProcessError', 'Error in smoothing process: %s', ME.message);
    fprintf('Stack trace:\n');
    for k = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(k).file, ME.stack(k).line);
    end
end
