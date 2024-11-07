function cellDataStruct = flagOutliersInPooledData(cellDataStruct, unitFilter, plotOutliers)
    % flagOutliersInPooledData: Identifies and flags outlier units on both experimental and recording levels.
    % Outliers are defined as units with maximum firing rates > mean + 2*std on either level.
    % Optionally plots outlier PSTHs with a summary table.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all units and response data.
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').
    %   - plotOutliers: Boolean indicating whether to plot PSTHs and table for flagged outliers.

    if nargin < 3
        plotOutliers = false; % Default: do not plot
    end

    % Initialize arrays to store PSTHs and unit info by response type across the experimental groups
    decreasedUnitIDs = {};
    decreasedPSTHs = [];

    % Loop through 'Emx' and 'Pvalb' groups to gather all 'Decreased' units for pooled analysis
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

                % Collect 'Decreased' units for both experimental and recording levels
                if isfield(unitData, 'psthSmoothed') && strcmp(unitData.responseType, 'Decreased')
                    decreasedPSTHs = [decreasedPSTHs; unitData.psthSmoothed];
                    decreasedUnitIDs{end+1} = struct('group', groupName, ...
                                                     'recording', recordingName, ...
                                                     'id', unitID, ...
                                                     'psthRaw', unitData.psthRaw);
                end
            end
        end
    end

    % Identify outliers among 'Decreased' units
    if ~isempty(decreasedPSTHs)
        maxFiringRatesExp = max(decreasedPSTHs, [], 2);  % Maximum firing rate per unit
        outlierThresholdExp = mean(maxFiringRatesExp) + 2 * std(maxFiringRatesExp);
        isOutlierExp = maxFiringRatesExp > outlierThresholdExp;

        % Tag outliers in cellDataStruct
        for i = find(isOutlierExp)'
            unitInfo = decreasedUnitIDs{i};
            cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = true;
        end

        % Optional: Plot outlier PSTHs and table if plotOutliers is true
        if plotOutliers
            plotOutlierPSTHs(cellDataStruct, decreasedUnitIDs(isOutlierExp), maxFiringRatesExp(isOutlierExp));
        end
    end

    % Display flagged outliers
    displayFlaggedOutliers(cellDataStruct);
end

function plotOutlierPSTHs(cellDataStruct, outlierUnits, maxFiringRates)
    % plotOutlierPSTHs: Plots the raw and smoothed PSTHs of outliers, with a summary table below.
    %
    % Inputs:
    %   - cellDataStruct: Main data structure containing unit data.
    %   - outlierUnits: Array of outlier unit information structs.
    %   - maxFiringRates: Array of maximum firing rates for each outlier.

    numOutliers = length(outlierUnits);
    figure('Position', [100, 100, 1200, 300 + 200 * numOutliers]); % Dynamically adjust figure size

    % Loop through each outlier and plot their PSTHs
    for i = 1:numOutliers
        unitInfo = outlierUnits{i};
        groupName = unitInfo.group;
        recordingName = unitInfo.recording;
        unitID = unitInfo.id;
        unitData = cellDataStruct.(groupName).(recordingName).(unitID);
        
        % Plot raw PSTH
        subplot(numOutliers, 2, (i-1)*2 + 1);
        plot(unitData.binEdges(1:end-1), unitData.psthRaw, 'Color', [0.7, 0.7, 0.7]);
        title(sprintf('Raw PSTH - Unit %s (%s/%s)', unitID, groupName, recordingName));
        xlabel('Time (s)');
        ylabel('Firing Rate (spikes/s)');

        % Plot smoothed PSTH
        subplot(numOutliers, 2, (i-1)*2 + 2);
        plot(unitData.binEdges(1:end-1), unitData.psthSmoothed, 'r', 'LineWidth', 1.5);
        title(sprintf('Smoothed PSTH - Unit %s (%s/%s)', unitID, groupName, recordingName));
        xlabel('Time (s)');
        ylabel('Firing Rate (spikes/s)');
    end

    % Add table below the plots summarizing each outlier’s firing rate and std deviation
    firingRates = maxFiringRates;
    stdDevs = cellfun(@(u) std(cellDataStruct.(u.group).(u.recording).(u.id).psthSmoothed), outlierUnits);

    % Position table
    uitable('Data', [extractfield(outlierUnits, 'id')', extractfield(outlierUnits, 'group')', ...
                     extractfield(outlierUnits, 'recording')', num2cell(firingRates'), num2cell(stdDevs')], ...
            'ColumnName', {'Unit', 'Group', 'Recording', 'Firing Rate', 'Std. Dev.'}, ...
            'RowName', [], ...
            'Units', 'normalized', 'Position', [0.05 0.02 0.9 0.2]);
end

function displayFlaggedOutliers(cellDataStruct)
    % Display flagged outliers in table format with experimental and recording-level flags.

    % Initialize table variables
    flaggedUnits = [];
    flaggedGroup = [];
    flaggedRecording = [];
    flaggedFiringRate = [];
    flaggedStdDev = [];
    flaggedOutlierType = [];

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
                
                % Check for recording-level and experimental-level outliers
                if isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
                    outlierType = 'Experimental';
                elseif isfield(unitData, 'isOutlierRecording') && unitData.isOutlierRecording
                    outlierType = 'Recording';
                else
                    continue; % Skip if not flagged as an outlier
                end

                % Append outlier information
                flaggedUnits = [flaggedUnits; {unitID}];
                flaggedGroup = [flaggedGroup; {groupName}];
                flaggedRecording = [flaggedRecording; {recordingName}];
                flaggedFiringRate = [flaggedFiringRate; max(unitData.psthSmoothed)];
                flaggedStdDev = [flaggedStdDev; std(unitData.psthSmoothed)];
                flaggedOutlierType = [flaggedOutlierType; {outlierType}];
            end
        end
    end

    % Display table
    flaggedTable = table(flaggedUnits, flaggedGroup, flaggedRecording, flaggedFiringRate, flaggedStdDev, flaggedOutlierType, ...
        'VariableNames', {'Unit', 'Group', 'Recording', 'Firing Rate', 'Std. Dev.', 'Outlier Type'});
    disp('Flagged Outlier Units:');
    disp(flaggedTable);
end
