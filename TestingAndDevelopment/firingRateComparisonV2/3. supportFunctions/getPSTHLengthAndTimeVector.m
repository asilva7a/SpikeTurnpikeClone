function [psthLength, timeVector] = getPSTHLengthAndTimeVector(cellDataStruct, groupName)
    % getPSTHLengthAndTimeVector: Helper function for poolResponsiveUnitsAndCalculatePSTH.
    % Determines the PSTH length and time vector from the first responsive unit.
    %
    % Called by:
    %   - poolResponsiveUnitsAndCalculatePSTH
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all groups and units.
    %   - groupName: Name of the group to extract PSTH length and time vector from.
    %
    % Outputs:
    %   - psthLength: Length of the PSTH (number of bins).
    %   - timeVector: Vector of time points for the PSTH bins.

    recordingNames = fieldnames(cellDataStruct.(groupName));
    for r = 1:numel(recordingNames)
        units = fieldnames(cellDataStruct.(groupName).(recordingNames{r}));
        units(strcmp(units, 'recordingData')) = [];  % Exclude `recordingData`
        for u = 1:numel(units)
            unitData = cellDataStruct.(groupName).(recordingNames{r}).(units{u});
            if isfield(unitData, 'responseType') && isfield(unitData, 'psthSmoothed') && ...
               (strcmp(unitData.responseType, 'Increased') || strcmp(unitData.responseType, 'Decreased'))
                psthLength = length(unitData.psthSmoothed);
                binWidth = unitData.binWidth;
                binEdges = unitData.binEdges;
                timeVector = binEdges(1:end-1) + binWidth / 2;
                return;
            end
        end
    end
    error('No responsive units found in group %s.', groupName);
end
