function cellDataStruct = flagOutliersInPooledData(cellDataStruct, unitFilter, plotOutliers)
    % flagOutliersInPooledData: Identifies and flags outlier units based on smoothed PSTHs (`psthSmoothed`) 
    % separately on recording and experimental group levels. Optionally plots flagged PSTHs with a summary.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all units and response data.
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').
    %   - plotOutliers: Boolean indicating whether to plot PSTHs and tables for flagged outliers.

    % Default input setup for debugging
    if nargin < 3
        plotOutliers = true; % Enable plotting for debugging
    end
    if nargin < 2
        unitFilter = 'both'; % Include both single and multi-units
    end
    if nargin < 1
        % Load or initialize a sample cellDataStruct if not provided
        try
            load('/home/silva7a-local/Documents/MATLAB/Data/eb_recordings/SpikeStuff/cellDataStruct.mat'); % Replace with your sample file path
            fprintf('Debug: Loaded default cellDataStruct from file.\n');
        catch
            error('cellDataStruct not provided and no default file found. Please provide a cellDataStruct.');
        end
    end

    % Define response types
    responseTypes = {'Increased', 'Decreased', 'NoChange'}; 
    
    % Initialize structures for storing PSTH data and unit info
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
    
   % Identify and flag outliers on the experimental group level using IQR
    for rType = responseTypes
        if ~isempty(psthDataGroup.(rType{1}))
            % Calculate the maximum firing rates for each unit in this response type
            maxRatesGroup = max(psthDataGroup.(rType{1}), [], 2);
    
            % Calculate Q1, Q3, and IQR
            Q1 = prctile(maxRatesGroup, 25); % First quartile (25th percentile)
            Q3 = prctile(maxRatesGroup, 75); % Third quartile (75th percentile)
            IQR_value = Q3 - Q1; % Interquartile range
    
            % Define outlier thresholds based on IQR
            lowerThreshold = Q1 - 1.5 * IQR_value;
            upperThreshold = Q3 + 1.5 * IQR_value;
    
            % Identify units that are outliers based on the IQR thresholds
            isOutlierGroup = maxRatesGroup < lowerThreshold | maxRatesGroup > upperThreshold;
    
            % Flag outliers in the cellDataStruct
            for i = find(isOutlierGroup)'
                unitInfo = unitInfoGroup.(rType{1}){i};
                cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = true;
            end
        end
    end

    
    % Display flagged outliers in separate tables after the outliers are flagged
    displayFlaggedOutliers(cellDataStruct, 'Recording');
    displayFlaggedOutliers(cellDataStruct, 'Experimental');
    
    % Optional: Plot outlier PSTHs after tables are populated
    if plotOutliers
        plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup);
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
    disp(['Flagged Outlier Units (' level ' Level):']);
    disp(flaggedTable);
end