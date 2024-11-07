function cellDataStruct = flagOutliersInPooledData(cellDataStruct, unitFilter, plotOutliers)
    % flagOutliersInPooledData: Identifies and flags outlier units based on smoothed PSTHs (`psthSmoothed`) 
    % separately on recording and experimental group levels.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all units and response data.
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').
    %   - plotOutliers: Boolean indicating whether to plot PSTHs and table for flagged outliers.
    
    % Set default input values for debugging
    if nargin < 3
        plotOutliers = true;
    end
    if nargin < 2
        unitFilter = 'both';
    end
    
    responseTypes = {'Increased', 'Decreased', 'NoChange'}; % Update 'No Change' to 'NoChange' to match variable names
    
    % Initialize structures to collect PSTH data and unit info
    psthDataRecording = struct();
    unitInfoRecording = struct();
    psthDataGroup = struct();
    unitInfoGroup = struct();
    
    % Set up empty arrays for each response type for both levels
    for rType = responseTypes
        psthDataRecording.(rType{1}) = {};
        psthDataGroup.(rType{1}) = [];
        unitInfoRecording.(rType{1}) = {};
        unitInfoGroup.(rType{1}) = {};
    end
    
    experimentGroups = {'Emx', 'Pvalb'};
    
    % Loop through each experimental group and collect PSTH data
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        if ~isfield(cellDataStruct, groupName)
            warning('Group %s not found in cellDataStruct. Skipping.', groupName);
            continue;
        end
        
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Loop through each recording within the experimental group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Reset recording-level data
            recordingPSTH = struct();
            for rType = responseTypes
                recordingPSTH.(rType{1}) = [];
                psthDataRecording.(rType{1}){end+1} = [];
            end
            
            % Collect data for each unit within the recording
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Apply unit filter
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if (strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                   (strcmp(unitFilter, 'multi') && isSingleUnit)
                    continue;
                end
                
                % Normalize 'No Change' responseType to 'NoChange'
                responseType = strrep(unitData.responseType, ' ', '');
                
                % Store PSTH data for each response type at both recording and group levels
                if isfield(unitData, 'psthSmoothed')
                    recordingPSTH.(responseType) = [recordingPSTH.(responseType); unitData.psthSmoothed];
                    psthDataGroup.(responseType) = [psthDataGroup.(responseType); unitData.psthSmoothed];
                    unitInfoRecording.(responseType){end+1} = struct('group', groupName, 'recording', recordingName, 'id', unitID);
                    unitInfoGroup.(responseType){end+1} = struct('group', groupName, 'recording', recordingName, 'id', unitID);
                end
            end
            
            % Identify and flag outliers on the recording level
            for rType = responseTypes
                if ~isempty(recordingPSTH.(rType{1}))
                    maxRates = max(recordingPSTH.(rType{1}), [], 2);
                    threshold = mean(maxRates) + 2 * std(maxRates);
                    isOutlier = maxRates > threshold;
                    
                    for i = find(isOutlier)'
                        unitInfo = unitInfoRecording.(rType{1}){i};
                        cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierRecording = true;
                    end
                end
            end
        end
    end
    
    % Identify and flag outliers on the experimental group level
    for rType = responseTypes
        if ~isempty(psthDataGroup.(rType{1}))
            maxRatesGroup = max(psthDataGroup.(rType{1}), [], 2);
            thresholdGroup = mean(maxRatesGroup) + 2 * std(maxRatesGroup);
            isOutlierGroup = maxRatesGroup > thresholdGroup;
            
            for i = find(isOutlierGroup)'
                unitInfo = unitInfoGroup.(rType{1}){i};
                cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = true;
            end
        end
    end
    
    % Display flagged outliers in separate tables
    displayFlaggedOutliers(cellDataStruct, 'Recording');
    displayFlaggedOutliers(cellDataStruct, 'Experimental');
    
    % Optional: Plot outlier PSTHs
    if plotOutliers
        plotOutlierPSTHs(cellDataStruct, psthDataGroup, unitInfoGroup);
    end
end

function displayFlaggedOutliers(cellDataStruct, level)
    % Display flagged outliers in table format for a specific level (Recording or Experimental)

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
                
                % Check for level-specific outliers
                if strcmp(level, 'Recording') && isfield(unitData, 'isOutlierRecording') && unitData.isOutlierRecording
                    flaggedUnits = [flaggedUnits; {unitID}];
                    flaggedGroup = [flaggedGroup; {groupName}];
                    flaggedRecording = [flaggedRecording; {recordingName}];
                    flaggedFiringRate = [flaggedFiringRate; max(unitData.psthSmoothed)];
                    flaggedStdDev = [flaggedStdDev; std(unitData.psthSmoothed)];
                elseif strcmp(level, 'Experimental') && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
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
    fprintf('Flagged Outlier Units (%s Level):\n', level);
    disp(flaggedTable);
end

function plotOutlierPSTHs(cellDataStruct, psthData, unitInfo)
    % plotOutlierPSTHs: Optionally plots the PSTHs for outlier units alongside a summary table.

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

    % Display summary table in the second tile
    ax2 = nexttile(t, 2);
    set(ax2, 'Visible', 'off');
    displayFlaggedOutliers(cellDataStruct, 'Recording');
    displayFlaggedOutliers(cellDataStruct, 'Experimental');
end

