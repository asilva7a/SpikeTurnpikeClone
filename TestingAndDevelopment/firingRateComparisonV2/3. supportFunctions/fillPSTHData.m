function psthData = fillPSTHData(cellDataStruct, responsiveCIDs, psthData)
    % fillPSTHData: Helper function for poolResponsiveUnitsAndCalculatePSTH.
    % Fills preallocated PSTH data array with smoothed PSTH data for responsive units.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all groups and units.
    %   - responsiveCIDs: List of responsive CIDs in the format {groupName, recordingName, unitName}.
    %   - psthData: Preallocated matrix to hold PSTH data.
    %
    % Outputs:
    %   - psthData: Updated matrix with PSTHs for responsive units.

    % Iterate through responsive CIDs and fill data
    for i = 1:numel(responsiveCIDs)
        cid = responsiveCIDs{i};
        
        try
            % Attempt to access the data using the specified group, recording, and unit names
            unitData = cellDataStruct.(cid{1}).(cid{2}).(cid{3});
            psthData(i, :) = unitData.psthSmoothed(:)';
        catch
            % Provide a detailed error message if the path is invalid
            error('Error accessing data in cellDataStruct. Check if group "%s", recording "%s", or unit "%s" exists.', ...
                  cid{1}, cid{2}, cid{3});
        end
    end
end
