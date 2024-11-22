function cellDataStruct = copyAmplitudeData(all_data, cellDataStruct)
    % Loop through the nested structure to copy amplitude data
    groupNames = fieldnames(all_data);
    
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(all_data.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(all_data.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                
                % Check if unit exists in cellDataStruct
                if ~isfield(cellDataStruct, groupName) || ...
                   ~isfield(cellDataStruct.(groupName), recordingName) || ...
                   ~isfield(cellDataStruct.(groupName).(recordingName), unitID)
                    fprintf('Skipping unit %s in %s/%s - not found in cellDataStruct\n', ...
                        unitID, groupName, recordingName);
                    continue;
                end
                
                % Extract amplitude from all_data
                if isfield(all_data.(groupName).(recordingName).(unitID), 'Amplitude')
                    amplitude_data = all_data.(groupName).(recordingName).(unitID).Amplitude;
                    
                    % Copy to cellDataStruct
                    cellDataStruct.(groupName).(recordingName).(unitID).Amplitude = amplitude_data;
                end
            end
        end
    end
end