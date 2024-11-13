function cellDataStruct = getCleanUnits(cellDataStruct)
    % Get all groups
    groupNames = fieldnames(cellDataStruct);
    
    % Loop through structure
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Track units to remove
            unitsToRemove = {};
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Check both flags for filtering
                if unitData.hasSquareWave || unitData.isOutlierExperimental
                    unitsToRemove{end+1} = unitID;
                end
            end
            
            % Remove tagged units
            for u = 1:length(unitsToRemove)
                cellDataStruct.(groupName).(recordingName) = ...
                    rmfield(cellDataStruct.(groupName).(recordingName), unitsToRemove{u});
            end
            
            % Remove empty recordings
            if isempty(fieldnames(cellDataStruct.(groupName).(recordingName)))
                cellDataStruct.(groupName) = rmfield(cellDataStruct.(groupName), recordingName);
            end
        end
        
        % Remove empty groups
        if isempty(fieldnames(cellDataStruct.(groupName)))
            cellDataStruct = rmfield(cellDataStruct, groupName);
        end
    end
end
