function [cellDataStruct, sparseUnitsList] = tagSparseUnits(cellDataStruct, frBefore, binWidth, minFrRate, projectData)
    %tagSparseUnits Tags units with firing rates below threshold and identifies single-firing units
    %   Inputs:
    %       cellDataStruct: Nested structure containing unit data
    %       frBefore: Firing rates before treatment
    %       binWidth: Width of time bins in seconds
    %       minFrRate: Minimum firing rate threshold (default 0.5 Hz)
    %       projectData: Optional path for saving results
    %   Outputs:
    %       cellDataStruct: Updated structure with sparse unit tags
    %       sparseUnitsList: Table containing sparse unit information
    
    % Set default args
    if nargin < 4 || isempty(minFrRate)
        minFrRate = 0.5; % set min fr rate to 0.5Hz
    end
    
    % Get total number of units for table initialization
    numFields = 0;
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        recordings = fieldnames(cellDataStruct.(groupNames{g}));
        for r = 1:length(recordings)
            units = fieldnames(cellDataStruct.(groupNames{g}).(recordings{r}));
            numFields = numFields + length(units);
        end
    end
    
    % Initiate data table with additional columns for single-firing detection
    unitTable = table('Size', [numFields, 7], ...
                      'VariableTypes', {'string', 'string', 'string', ...
                                        'double', 'double', 'double', 'logical'}, ...
                      'VariableNames', {'unitID', 'recordingName', 'groupName', ...
                                        'sparseScore', 'initialFiringRate', ...
                                        'laterFiringRate', 'isSingleFiring'});
    
    % Initialize counter for table rows
    rowCounter = 1;

    % Loop through groups, recordings, and units
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Get PSTH data
                psthData = unitData.psthSmoothed;
                timeVector = unitData.binEdges(1:end-1) + binWidth/2;
                
                % Define analysis windows more precisely
                earlyWindow = timeVector <= 20;  % First 20 seconds
                lateWindow = timeVector > 20;    % After 20 seconds
                
                % Calculate metrics
                maxEarlyFiring = max(psthData(earlyWindow));
                meanLateFiring = mean(psthData(lateWindow));
                
                % Criteria for single-firing pattern:
                % 1. Strong early firing (> minFrRate)
                % 2. Very low firing later (< 10% of peak)
                % 3. Early peak must be significant compared to overall activity
                isSingleFiring = (maxEarlyFiring > minFrRate) && ...
                                (meanLateFiring < 0.1 * maxEarlyFiring) && ...
                                (maxEarlyFiring > 5 * meanLateFiring);
                
                sparseScore = meanLateFiring/minFrRate;
                
                % Update unit structure
                cellDataStruct.(groupName).(recordingName).(unitID).isSingleFiring = isSingleFiring;
                cellDataStruct.(groupName).(recordingName).(unitID).singleFiringMetrics = struct(...
                    'maxEarlyFiring', maxEarlyFiring, ...
                    'meanLateFiring', meanLateFiring, ...
                    'earlyToLateRatio', maxEarlyFiring/meanLateFiring);
                
                % Add to table
                unitTable.unitID(rowCounter) = string(unitID);
                unitTable.recordingName(rowCounter) = string(recordingName);
                unitTable.groupName(rowCounter) = string(groupName);
                unitTable.sparseScore(rowCounter) = sparseScore;
                unitTable.maxEarlyFiring(rowCounter) = maxEarlyFiring;
                unitTable.meanLateFiring(rowCounter) = meanLateFiring;
                unitTable.isSingleFiring(rowCounter) = isSingleFiring;
                
                rowCounter = rowCounter + 1;
            end     
        end
    end

    % Create output table of sparse and single-firing units
    sparseUnitsList = unitTable(unitTable.isSingleFiring, :);
    
    % Sort by sparseScore for easier analysis
    sparseUnitsList = sortrows(sparseUnitsList, 'sparseScore', 'ascend');

    % Sort by early-to-late firing ratio for easier analysis
    sparseUnitsList = sortrows(sparseUnitsList, 'maxEarlyFiring', 'descend');
    
    % Optional: save sparseUnitList to projectData
    if nargin > 4 && ~isempty(projectData)
        try
            timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
            fileName = sprintf('sparseUnitsTable_%s.csv', timeStamp);
            
            saveDir = fullfile(projectData, 'sparseUnitTable');
            if ~exist(saveDir, 'dir')
                mkdir(saveDir);
            end
            
            savePath = fullfile(saveDir, fileName);
            writetable(sparseUnitsList, savePath);
            
            fprintf('Successfully saved to %s\n', savePath);
            
        catch ME
            fprintf('Error saving sparse units table:\n');
            fprintf('Message: %s\n', ME.message);
            fprintf('Stack:\n');
            for k = 1:length(ME.stack)
                fprintf('File: %s, Line: %d, Function: %s\n', ...
                    ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
            end
        end
    end
end


