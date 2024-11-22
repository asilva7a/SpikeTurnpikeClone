function countSingleUnits(cellDataStruct)
    % Initialize counters
    groupCounts = struct();
    
    % Process each group
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        singleUnitCount = 0;
        
        % Process recordings in group
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Count single units
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                if isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1
                    singleUnitCount = singleUnitCount + 1;
                end
            end
        end
        
        % Store count for group
        groupCounts.(groupName) = singleUnitCount;
        fprintf('%s: %d single units\n', groupName, singleUnitCount);
    end
end
