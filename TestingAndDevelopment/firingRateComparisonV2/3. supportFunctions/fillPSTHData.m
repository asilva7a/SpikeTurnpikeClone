function psthData = fillPSTHData(cellDataStruct, responsiveCIDs, psthData)
    % fillPSTHData: Helper function for poolResponsiveUnitsAndCalculatePSTH.
    % Fills preallocated PSTH data array with smoothed PSTH data for responsive units.
    %
    % Called by:
    %   - poolResponsiveUnitsAndCalculatePSTH
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all groups and units.
    %   - responsiveCIDs: List of responsive CIDs.
    %   - psthData: Preallocated matrix to hold PSTH data.
    %
    % Outputs:
    %   - psthData: Updated matrix with PSTHs for responsive units.

    % Iterate through responsive CIDs and fill data
    for i = 1:numel(responsiveCIDs)
        cid = responsiveCIDs{i};
        unitData = cellDataStruct.(cid{1}).(cid{2}).(cid{3});
        psthData(i, :) = unitData.psthSmoothed(:)';
    end
end
