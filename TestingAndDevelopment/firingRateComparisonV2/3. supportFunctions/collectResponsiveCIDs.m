function responsiveCIDs = collectResponsiveCIDs(cellDataStruct, groupName)
    % collectResponsiveCIDs: Collects CIDs of responsive units in a given group.
    % Each entry in responsiveCIDs should be a cell array in the format: {groupName, recordingName, unitName}.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all groups and units.
    %   - groupName: Name of the group to extract CIDs from.
    %
    % Outputs:
    %   - responsiveCIDs: Cell array with CIDs of responsive units in the format {groupName, recordingName, unitName}.
    
    responsiveCIDs = {};

    % Loop through each recording in the group
    recordingNames = fieldnames(cellDataStruct.(groupName));
    for r = 1:numel(recordingNames)
        units = fieldnames(cellDataStruct.(groupName).(recordingNames{r}));
        units(strcmp(units, 'recordingData')) = [];  % Exclude `recordingData`
        for u = 1:numel(units)
            unitData = cellDataStruct.(groupName).(recordingNames{r}).(units{u});
            if isfield(unitData, 'responseType') && ...
               (strcmp(unitData.responseType, 'Increased') || strcmp(unitData.responseType, 'Decreased'))
                % Append in the format {groupName, recordingName, unitName}
                responsiveCIDs{end+1, 1} = {groupName, recordingNames{r}, units{u}};
            end
        end
    end
end
