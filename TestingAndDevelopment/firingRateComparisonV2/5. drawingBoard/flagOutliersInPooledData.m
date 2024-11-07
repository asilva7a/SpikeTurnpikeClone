function cellDataStruct = flagOutliersInPooledData(cellDataStruct, unitFilter, plotOutliers)
    % flagOutliersInPooledData: Identifies and flags outlier units across all response types.
    % Outliers are defined as units with maximum firing rates > mean + 2*std within each response type.
    % Optionally plots outlier PSTHs with a summary table at the bottom.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all units and response data.
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').
    %   - plotOutliers: Boolean indicating whether to plot PSTHs and table for flagged outliers.

    if nargin < 3
        plotOutliers = false; % Default: do not plot
    end

    % Initialize dictionaries for storing PSTHs and unit info by response type
    responseTypes = {'Increased', 'Decreased', 'NoChange'};  % Updated to 'NoChange'
    psthData = struct();
    unitIDs = struct();

    % Prepare empty fields for each response type
    for rType = responseTypes
        psthData.(rType{1}) = [];
        unitIDs.(rType{1}) = {};
    end

    % Collect units by response type across 'Emx' and 'Pvalb' groups
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

                % Collect PSTH data for each response type
                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                    responseType = unitData.responseType;
                    psthData.(responseType) = [psthData.(responseType); unitData.psthSmoothed];
                    unitIDs.(responseType){end+1} = struct('group', groupName, ...
                                                           'recording', recordingName, ...
                                                           'id', unitID, ...
                                                           'psthRaw', unitData.psthRaw);
                end
            end
        end
    end

    % Identify and flag outliers for each response type
    for rType = responseTypes
        rTypeName = rType{1};
        psths = psthData.(rTypeName);

        if ~isempty(psths)
            maxFiringRates = max(psths, [], 2);  % Maximum firing rate per unit
            outlierThreshold = mean(maxFiringRates) + 2 * std(maxFiringRates);
            isOutlier = maxFiringRates > outlierThreshold;

            % Tag outliers in cellDataStruct
            for i = find(isOutlier)'
                unitInfo = unitIDs.(rTypeName){i};
                cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).(['isOutlier_', rTypeName]) = true;
            end

            % Optional: Plot outlier PSTHs and table if plotOutliers is true
            if plotOutliers && any(isOutlier)
                plotOutlierPSTHs(cellDataStruct, unitIDs.(rTypeName)(isOutlier), maxFiringRates(isOutlier), rTypeName);
            end
        end
    end

    % Display flagged outliers
    displayFlaggedOutliers(cellDataStruct);
end

function plotOutlierPSTHs(cellDataStruct, outlierUnits, maxFiringRates, responseType)
    % plotOutlierPSTHs: Plots the raw and smoothed PSTHs of outliers, with a summary table below.
    %
    % Inputs:
    %   - cellDataStruct: Main data structure containing unit data.
    %   - outlierUnits: Array of outlier unit information structs.
    %   - maxFiringRates: Array of maximum firing rates for each outlier.
    %   - responseType: Response type of the outliers being plotted.

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
        title(sprintf('Raw PSTH - %s Unit %s (%s/%s)', responseType, unitID, groupName, recordingName));
        xlabel('Time (s)');
        ylabel('Firing Rate (spikes/s)');

        % Plot smoothed PSTH
        subplot(numOutliers, 2, (i-1)*2 + 2);
        plot(unitData.binEdges(1:end-1), unitData.psthSmoothed, 'r', 'LineWidth', 1.5);
        title(sprintf('Smoothed PSTH - %s Unit %s (%s/%s)', responseType, unitID, groupName, recordingName));
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
    % Display flagged outliers in table format, indicating response type flags.

    % Initialize table variables
    flaggedUnits = [];
    flaggedGroup = [];
    flaggedRecording = [];
    flaggedFiringRate = [];
    flaggedStdDev = [];
    flaggedResponseType = [];

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

                % Check for outlier flags by response type
                for responseType = {'Increased', 'Decreased', 'NoChange'}
                    outlierField = ['isOutlier_', responseType{1}];
                    if isfield(unitData, outlierField) && unitData.(outlierField)
                        % Append outlier information
                        flaggedUnits = [flaggedUnits; {unitID}];
                        flaggedGroup = [flaggedGroup; {groupName}];
                        flaggedRecording = [flaggedRecording; {recordingName}];
                        flaggedFiringRate = [flaggedFiringRate; max(unitData.psthSmoothed)];
                        flaggedStdDev = [flaggedStdDev; std(unitData.psthSmoothed)];
                        flaggedResponseType = [flaggedResponseType; {responseType{1}}];
                    end
                end
            end
        end
    end

    % Display table
    flaggedTable = table(flaggedUnits, flaggedGroup, flaggedRecording, flaggedFiringRate, flaggedStdDev, flaggedResponseType, ...
        'VariableNames', {'Unit', 'Group', 'Recording', 'Firing Rate', 'Std. Dev.', 'Response Type'});
    disp('Flagged Outlier Units:');
    disp(flaggedTable);
end
