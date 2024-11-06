function cellDataStruct = poolResponsiveUnitsAndCalculatePSTH(cellDataStruct, treatmentTime)
    % poolResponsiveUnitsAndCalculatePSTH: Main function to pool responsive units from Control and Experimental groups,
    % calculate the average smoothed PSTH and SEM for each, and save the results back into cellDataStruct.
    % This function relies on several helper functions to perform its tasks:
    %   - collectResponsiveCIDs.m: Collects the CIDs (identifiers) of responsive units in each group.
    %   - getPSTHLengthAndTimeVector.m: Determines the PSTH length and constructs a time vector.
    %   - fillPSTHData.m: Fills a preallocated array with smoothed PSTH data for responsive units.
    %   - calculateMeanAndSEM.m: Calculates the mean and SEM of the PSTH data across units.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all group, recording, and unit data.
    %   - treatmentTime: Time in seconds where treatment was administered.
    %
    % Outputs:
    %   - cellDataStruct: Updated structure with pooled PSTH and SEM for Control and Experimental groups.

    if nargin < 2
        treatmentTime = 1860;  % Default treatment time if not provided
    end

    % Define group names for Control and Experimental
    controlGroup = 'Control';
    experimentalGroups = {'emx', 'pvalb'};

    % Step 1: Collect CIDs of responsive units
    controlUnitCIDs = collectResponsiveCIDs(cellDataStruct, controlGroup);
    experimentalUnitCIDs = [];
    for i = 1:numel(experimentalGroups)
        experimentalUnitCIDs = [experimentalUnitCIDs; collectResponsiveCIDs(cellDataStruct, experimentalGroups{i})];
    end

    % Step 2: Preallocate storage arrays
    [psthLength, timeVector] = getPSTHLengthAndTimeVector(cellDataStruct, controlGroup);
    controlPSTHs = NaN(numel(controlUnitCIDs), psthLength);
    experimentalPSTHs = NaN(numel(experimentalUnitCIDs), psthLength);

    % Step 3: Fill the preallocated arrays with PSTH data
    controlPSTHs = fillPSTHData(cellDataStruct, controlUnitCIDs, controlPSTHs);
    experimentalPSTHs = fillPSTHData(cellDataStruct, experimentalUnitCIDs, experimentalPSTHs);

    % Step 4: Calculate the average PSTH and SEM for Control and Experimental groups
    [controlAvgPSTH, controlSEMPSTH] = calculateMeanAndSEM(controlPSTHs);
    [experimentalAvgPSTH, experimentalSEMPSTH] = calculateMeanAndSEM(experimentalPSTHs);

    % Step 5: Save results into cellDataStruct under expData.Control and expData.Experimental
    cellDataStruct.expData.Control.pooledResponses.avgPSTH = controlAvgPSTH;
    cellDataStruct.expData.Control.pooledResponses.semPSTH = controlSEMPSTH;
    cellDataStruct.expData.Control.pooledResponses.timeVector = timeVector;

    cellDataStruct.expData.Experimental.pooledResponses.avgPSTH = experimentalAvgPSTH;
    cellDataStruct.expData.Experimental.pooledResponses.semPSTH = experimentalSEMPSTH;
    cellDataStruct.expData.Experimental.pooledResponses.timeVector = timeVector;

    fprintf('Pooled PSTH data calculated and saved for Control and Experimental groups.\n');
end
