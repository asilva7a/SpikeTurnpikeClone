function cellDataStruct = flagOutliersInRecordingAUC(cellDataStruct)
    % flagOutliersInRecording: Flags units as outliers within each recording based on their PSTH area under the curve (AUC).
    % Prints a table of outliers with information on 'Unit', 'Group', 'Recording', 'AUC', and 'Std. Dev.'
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %
    % Outputs:
    %   - cellDataStruct: Updated data structure with `isOutlier` field added to each unit.

    % Initialize cell array to collect outlier information for the table
    outlierInfo = {'Unit', 'Group', 'Recording', 'AUC', 'Std. Dev.'};

    % Loop through each group and recording
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            
            % Initialize arrays for collecting AUCs by response type
            increasedAUCs = [];
            decreasedAUCs = [];
            noChangeAUCs = [];
            
            % Collect individual PSTHs and corresponding unit IDs for each response type
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            increasedUnitIDs = {};
            decreasedUnitIDs = {};
            noChangeUnitIDs = {};
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Check if the unit has required fields
                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                    psth = unitData.psthSmoothed;
                    auc = trapz(psth);  % Compute the area under the curve
                    
                    % Sort the units by their response type
                    switch unitData.responseType
                        case 'Increased'
                            increasedAUCs = [increasedAUCs; auc];
                            increasedUnitIDs{end+1} = unitID; %#ok<AGROW>
                        case 'Decreased'
                            decreasedAUCs = [decreasedAUCs; auc];
                            decreasedUnitIDs{end+1} = unitID; %#ok<AGROW>
                        case 'No Change'
                            noChangeAUCs = [noChangeAUCs; auc];
                            noChangeUnitIDs{end+1} = unitID; %#ok<AGROW>
                    end
                end
            end
            
            % Flag outliers for each response type
            [cellDataStruct, outlierInfo] = flagOutliersForCategory(cellDataStruct, groupName, recordingName, increasedUnitIDs, increasedAUCs, 'Increased', outlierInfo);
            [cellDataStruct, outlierInfo] = flagOutliersForCategory(cellDataStruct, groupName, recordingName, decreasedUnitIDs, decreasedAUCs, 'Decreased', outlierInfo);
            [cellDataStruct, outlierInfo] = flagOutliersForCategory(cellDataStruct, groupName, recordingName, noChangeUnitIDs, noChangeAUCs, 'No Change', outlierInfo);
        end
    end

    % Convert outlier information to a table and display it
    if size(outlierInfo, 1) > 1  % Check if there are any outliers
        outlierTable = cell2table(outlierInfo(2:end, :), 'VariableNames', outlierInfo(1, :));
        disp('Outlier Units Table:');
        disp(outlierTable);
    else
        disp('No outlier units detected.');
    end
end

%% Helper Function: Flag outliers for a specific response type and collect information
function [cellDataStruct, outlierInfo] = flagOutliersForCategory(cellDataStruct, groupName, recordingName, unitIDs, aucValues, responseType, outlierInfo)
    % flagOutliersForCategory: Flags units as outliers for a specific response type within a recording.
    %
    % Inputs:
    %   - cellDataStruct: Data structure to be updated
    %   - groupName: Name of the group
    %   - recordingName: Name of the recording
    %   - unitIDs: Cell array of unit IDs for this response type
    %   - aucValues: Array of AUC values for this response type
    %   - responseType: String specifying the response type ('Increased', 'Decreased', 'No Change')
    %   - outlierInfo: Cell array to collect outlier information for printing a summary table
    %
    % Outputs:
    %   - cellDataStruct: Updated data structure with `isOutlier` field for outliers in the specified category
    %   - outlierInfo: Updated cell array with outlier information

    if isempty(aucValues)
        return; % No data for this response type, skip
    end

    % Define outlier threshold (e.g., mean + 2*std)
    meanAUC = mean(aucValues);
    stdAUC = std(aucValues);
    outlierThreshold = meanAUC + 2 * stdAUC;
    
    % Identify outliers based on AUC
    isOutlier = aucValues > outlierThreshold;
    outlierIndices = find(isOutlier);
    
    % Update cellDataStruct to mark outliers
    for i = 1:length(outlierIndices)
        unitIdx = outlierIndices(i);
        unitID = unitIDs{unitIdx};
        
        % Set the `isOutlier` field for this unit to true
        cellDataStruct.(groupName).(recordingName).(unitID).isOutlier = true;
        
        % Collect outlier information for display
        outlierInfo{end+1, 1} = unitID;
        outlierInfo{end, 2} = groupName;
        outlierInfo{end, 3} = recordingName;
        outlierInfo{end, 4} = aucValues(unitIdx);  % AUC
        outlierInfo{end, 5} = stdAUC;              % Std. Dev.
    end
    
    % For non-outliers in this category, ensure `isOutlier` field is set to false
    nonOutlierIndices = find(~isOutlier);
    for i = 1:length(nonOutlierIndices)
        unitIdx = nonOutlierIndices(i);
        unitID = unitIDs{unitIdx};
        
        % Set the `isOutlier` field for this unit to false
        cellDataStruct.(groupName).(recordingName).(unitID).isOutlier = false;
    end
end
 