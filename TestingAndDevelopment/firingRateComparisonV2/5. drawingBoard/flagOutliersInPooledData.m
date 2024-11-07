function cellDataStruct = flagOutliersInPooledData(cellDataStruct, unitFilter)
    % flagOutliersInPooledData: Identifies and flags outlier units in the data structure.
    % Outliers are defined as units with maximum firing rates > mean + 2*std.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all units and response data.
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').

    % Initialize arrays to store unit IDs by response type
    decreasedUnitIDs = {};
    decreasedPSTHs = [];

    % Loop through 'Emx' and 'Pvalb' groups and gather all 'Decreased' units
    experimentGroups = {'Emx', 'Pvalb'};
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        if ~isfield(cellDataStruct, groupName)
            warning('Group %s not found in cellDataStruct. Skipping.', groupName);
            continue;
        end
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Apply unit filter based on IsSingleUnit field
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if (strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                   (strcmp(unitFilter, 'multi') && isSingleUnit)
                    continue; % Skip unit if it doesn't match the filter
                end

                % Collect 'Decreased' units
                if isfield(unitData, 'psthSmoothed') && strcmp(unitData.responseType, 'Decreased')
                    decreasedPSTHs = [decreasedPSTHs; unitData.psthSmoothed];
                    decreasedUnitIDs{end+1} = struct('group', groupName, ...
                                                     'recording', recordingName, ...
                                                     'id', unitID);
                end
            end
        end
    end

    % Identify outliers among 'Decreased' units
    if ~isempty(decreasedPSTHs)
        maxFiringRates = max(decreasedPSTHs, [], 2);  % Maximum firing rate per unit
        outlierThreshold = mean(maxFiringRates) + 2 * std(maxFiringRates);
        isOutlier = maxFiringRates > outlierThreshold;

        % Tag outliers in cellDataStruct
        for i = find(isOutlier)'
            unitInfo = decreasedUnitIDs{i};
            cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlier = true;
        end
    end

    % Display flagged outliers
    displayFlaggedOutliers(cellDataStruct);
end

function displayFlaggedOutliers(cellDataStruct)
    % Display flagged outliers in table format

    % Initialize table variables
    flaggedUnits = [];
    flaggedGroup = [];
    flaggedRecording = [];
    flaggedFiringRate = [];
    flaggedStdDev = [];

    % Gather outlier information
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
                if isfield(unitData, 'isOutlier') && unitData.isOutlier
                    flaggedUnits = [flaggedUnits; {unitID}];
                    flaggedGroup = [flaggedGroup; {groupName}];
                    flaggedRecording = [flaggedRecording; {recordingName}];
                    flaggedFiringRate = [flaggedFiringRate; max(unitData.psthSmoothed)];
                    flaggedStdDev = [flaggedStdDev; std(unitData.psthSmoothed)];
                end
            end
        end
    end

    % Display table
    flaggedTable = table(flaggedUnits, flaggedGroup, flaggedRecording, flaggedFiringRate, flaggedStdDev, ...
        'VariableNames', {'Unit', 'Group', 'Recording', 'Firing Rate', 'Std. Dev.'});
    disp('Flagged Outlier Units:');
    disp(flaggedTable);
end

