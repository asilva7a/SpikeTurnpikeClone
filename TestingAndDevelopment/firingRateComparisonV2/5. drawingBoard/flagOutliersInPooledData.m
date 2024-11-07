function cellDataStruct = flagOutliersInPooledData(cellDataStruct, unitFilter, plotOutliers)
    % flagOutliersInPooledData: Identifies and flags outlier units across all response types.
    % Outliers are defined as units with maximum firing rates > mean + 2*std within each response type.
    % Optionally plots outlier PSTHs with a summary table at the bottom.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all units and response data.
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').
    %   - plotOutliers: Boolean indicating whether to plot PSTHs and table for flagged outliers.

    % Default input setup for debugging
    if nargin < 3
        plotOutliers = true; % Enable plotting for debugging
    end
    if nargin < 2
        unitFilter = 'both'; % Include both single and multi-units
    end
    if nargin < 1
        % Load or initialize a sample cellDataStruct if not provided
        load('/path/to/sample/cellDataStruct.mat'); % Replace with your sample file path
        fprintf('Debug: Loaded default cellDataStruct from file.\n');
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

    % Loop through 'Emx' and 'Pvalb' groups and gather PSTHs for each response type
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

                % Handle responseType with space as 'NoChange'
                responseType = strrep(unitData.responseType, ' ', ''); % Remove spaces from responseType

                % Collect PSTH data based on response type
                if isfield(unitData, 'psthSmoothed')
                    psthData.(responseType) = [psthData.(responseType); unitData.psthSmoothed];
                    unitIDs.(responseType){end+1} = struct('group', groupName, ...
                                                           'recording', recordingName, ...
                                                           'id', unitID);
                end
            end
        end
    end

    % Identify outliers for each response type
    for rType = responseTypes
        responseType = rType{1};
        if ~isempty(psthData.(responseType))
            maxFiringRates = max(psthData.(responseType), [], 2);  % Max firing rate per unit
            outlierThreshold = mean(maxFiringRates) + 2 * std(maxFiringRates);
            isOutlier = maxFiringRates > outlierThreshold;

            % Tag outliers in cellDataStruct
            for i = find(isOutlier)'
                unitInfo = unitIDs.(responseType){i};
                cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlier = true;
                cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = true;
            end
        end
    end

    % Display flagged outliers
    displayFlaggedOutliers(cellDataStruct);

    % Optional: Plotting logic
    if plotOutliers
        plotOutlierPSTHs(cellDataStruct, psthData, unitIDs);
    end
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

function plotOutlierPSTHs(cellDataStruct, psthData, unitIDs)
    % plotOutlierPSTHs: Optionally plots the PSTHs for outlier units
    % alongside a summary table with outlier info.

    % Collect data for plotting
    figure;
    t = tiledlayout(2, 1);
    title(t, 'Outlier PSTHs and Summary Table');

    % Plot smoothed PSTHs for each response type
    ax1 = nexttile(t, 1);
    hold(ax1, 'on');
    responseTypes = fieldnames(psthData);
    colors = struct('Increased', [1, 0, 0], 'Decreased', [0, 0, 1], 'NoChange', [0.5, 0.5, 0.5]);
    
    for rType = responseTypes'
        responseType = rType{1};
        if ~isempty(psthData.(responseType))
            for i = 1:size(psthData.(responseType), 1)
                plot(ax1, psthData.(responseType)(i, :), 'Color', colors.(responseType), 'LineWidth', 0.5);
            end
        end
    end
    title(ax1, 'Outlier PSTHs by Response Type');
    legend(ax1, responseTypes);

    % Display summary table in second tile
    ax2 = nexttile(t, 2);
    set(ax2, 'Visible', 'off');
    displayFlaggedOutliers(cellDataStruct);
end
