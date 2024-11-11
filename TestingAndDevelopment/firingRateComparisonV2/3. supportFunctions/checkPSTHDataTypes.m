function dataTypeArray = checkPSTHDataTypes(cellDataStruct)
    % checkPSTHDataTypes: Creates an array indicating the data type of each entry in psthSmoothed.
    %
    % Inputs:
    %   - cellDataStruct: The main data structure containing groups, recordings, and units.
    %
    % Outputs:
    %   - dataTypeArray: A structure with the same hierarchy as cellDataStruct, where each unit's
    %     psthSmoothed is replaced by an array indicating the data type of each entry.

    % Initialize the output structure with the same fields as cellDataStruct
    dataTypeArray = struct();
    
    % Loop through groups, recordings, and units
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Check if psthSmoothed exists
                if isfield(unitData, 'psthSmoothed')
                    % Create an array indicating the data type of each element in psthSmoothed
                    psthSmoothed = unitData.psthSmoothed;
                    dataTypeArray.(groupName).(recordingName).(unitID) = arrayfun(@(x) class(x), psthSmoothed, 'UniformOutput', false);
                else
                    warning('No psthSmoothed data for Unit %s in %s, %s.', unitID, groupName, recordingName);
                    dataTypeArray.(groupName).(recordingName).(unitID) = 'No psthSmoothed data';
                end
            end
        end
    end
    
    % Display data types for debugging
    disp(dataTypeArray);
end
