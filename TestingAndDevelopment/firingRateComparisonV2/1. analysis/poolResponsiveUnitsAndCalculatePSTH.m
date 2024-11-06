function pooledData = poolResponsiveUnitsAndCalculatePSTH(cellDataStruct, treatmentTime)
    % poolResponsiveUnitsAndCalculatePSTH: Pools responsive units from Control and Experimental groups,
    % calculates the average smoothed PSTH and SEM for each.
    % Inputs:
    %   - cellDataStruct: Data structure containing all group, recording, and unit data.
    %   - treatmentTime: Time in seconds where treatment was administered.
    % Outputs:
    %   - pooledData: Struct with average PSTH and SEM for Control and Experimental groups.
    
    if nargin < 2
        treatmentTime = 1860;  % Default treatment time if not provided
    end

    % Define group names for Control and Experimental
    controlGroup = 'Control';
    experimentalGroups = {'emx', 'pvalb'};

    % Initialize containers for PSTH data
    controlPSTHs = [];
    experimentalPSTHs = [];

    % Process Control group
    controlPSTHs = extractResponsiveUnitPSTHs(cellDataStruct, controlGroup);

    % Process Experimental groups
    for i = 1:numel(experimentalGroups)
        groupName = experimentalGroups{i};
        expPSTHs = extractResponsiveUnitPSTHs(cellDataStruct, groupName);
        experimentalPSTHs = [experimentalPSTHs; expPSTHs];  % Append data to the pool
    end

    % Calculate the average PSTH and SEM for Control group
    [controlAvgPSTH, controlSEMPSTH, timeVector] = calculateMeanAndSEM(controlPSTHs);

    % Calculate the average PSTH and SEM for Experimental group
    [experimentalAvgPSTH, experimentalSEMPSTH] = calculateMeanAndSEM(experimentalPSTHs);

    % Package results into a struct for output
    pooledData = struct();
    pooledData.Control.avgPSTH = controlAvgPSTH;
    pooledData.Control.semPSTH = controlSEMPSTH;
    pooledData.Experimental.avgPSTH = experimentalAvgPSTH;
    pooledData.Experimental.semPSTH = experimentalSEMPSTH;
    pooledData.timeVector = timeVector;  % Common time vector for plotting

    fprintf('Pooled PSTH data calculated for Control and Experimental groups.\n');
end

function psthData = extractResponsiveUnitPSTHs(cellDataStruct, groupName)
    % extractResponsiveUnitPSTHs: Extracts the PSTH data for responsive units in a given group.
    % Inputs:
    %   - cellDataStruct: Data structure containing all groups and units.
    %   - groupName: Name of the group to extract PSTHs from.
    % Outputs:
    %   - psthData: Matrix of PSTH data for responsive units, with rows as units and columns as time bins.

    psthData = [];  % Initialize empty array to hold PSTH data

    % Iterate through each recording in the specified group
    recordingNames = fieldnames(cellDataStruct.(groupName));
    for r = 1:numel(recordingNames)
        recordingName = recordingNames{r};
        units = fieldnames(cellDataStruct.(groupName).(recordingName));
        units(strcmp(units, 'recordingData')) = [];  % Exclude `recordingData`

        % Collect PSTH data from responsive units
        for u = 1:numel(units)
            unitData = cellDataStruct.(groupName).(recordingName).(units{u});
            if isfield(unitData, 'responseType') && isfield(unitData, 'psthSmoothed')
                % Check if unit is responsive (e.g., "Increased" or "Decreased")
                if strcmp(unitData.responseType, 'Increased') || strcmp(unitData.responseType, 'Decreased')
                    psthData = [psthData; unitData.psthSmoothed(:)'];  % Append PSTH as a row
                end
            end
        end
    end
end

function [avgPSTH, semPSTH, timeVector] = calculateMeanAndSEM(psthData)
    % calculateMeanAndSEM: Calculates the mean and SEM of PSTH data.
    % Inputs:
    %   - psthData: Matrix where each row is a PSTH for a unit, and each column is a time bin.
    % Outputs:
    %   - avgPSTH: Average PSTH across units.
    %   - semPSTH: Standard error of the mean across units.
    %   - timeVector: Time vector corresponding to PSTH bins.

    if isempty(psthData)
        avgPSTH = [];
        semPSTH = [];
        timeVector = [];
        return;
    end

    % Calculate mean and SEM
    avgPSTH = mean(psthData, 1, 'omitnan');  % Mean across units
    semPSTH = std(psthData, 0, 1, 'omitnan') / sqrt(size(psthData, 1));  % SEM

    % Assume the time vector can be derived from the first unit's data if available
    % Here, we use a generic time vector (e.g., assuming uniform binning of 0.1 s)
    binWidth = 0.1;  % Adjust this as per actual bin width in your data
    timeVector = (0:(size(psthData, 2) - 1)) * binWidth;
end
