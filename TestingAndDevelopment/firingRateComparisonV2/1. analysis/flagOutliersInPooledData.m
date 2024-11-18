function [cellDataStruct, groupIQRs] = flagOutliersInPooledData(cellDataStruct, params, paths)
    
%% Main Function

    % Input validation
    if nargin < 1 || isempty(cellDataStruct)
        error('cellDataStruct is required');
    end
    
    % Set default parameters if not provided in params
    if ~isfield(params, 'unitFilter')
        params.unitFilter = 'both';
    end
    
    % Define response types and groups
    responseTypes = {'Increased', 'Decreased', 'No_Change'};
    experimentGroups = params.experimentGroups;
    
    % Initialize structures
    groupIQRs = struct();
    psthDataGroup = struct();
    unitInfoGroup = struct();
    
    % Initialize metrics structure for each response type and group
    for rType = responseTypes
        psthDataGroup.(rType{1}) = struct();
        unitInfoGroup.(rType{1}) = struct();
        groupIQRs.(rType{1}) = struct();
        
        for grp = experimentGroups
            psthDataGroup.(rType{1}).(grp{1}) = struct(...
                'maxFiringRate', [], ...
                'baselineRates', [], ...
                'treatmentRates', [], ...
                'cvValues', [], ...
                'metrics', []);
            unitInfoGroup.(rType{1}).(grp{1}) = {};
            groupIQRs.(rType{1}).(grp{1}) = struct(...
                'IQR', [], ...
                'Median', [], ...
                'UpperFence', [], ...
                'LowerFence', []);
        end
    end
    
    % Process each unit
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        if ~isfield(cellDataStruct, groupName)
            continue;
        end
        
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Initialize outlier flag
                cellDataStruct.(groupName).(recordingName).(unitID).isOutlierExperimental = 0;
                
                % Check if unit should be processed
                if ~shouldProcessUnit(unitData, params.unitFilter)
                    continue;
                end
                
                % Get response type
                responseType = unitData.responseType;
                if strcmp(responseType, 'MostlySilent') || strcmp(responseType, 'MostlyZero')
                    continue;
                end
                
                % Calculate metrics
                metrics = calculateUnitMetrics(unitData, params);
                
                % Store metrics and individual values
                if ~isfield(psthDataGroup.(responseType).(groupName), 'metrics')
                    psthDataGroup.(responseType).(groupName).metrics = [];
                end
                psthDataGroup.(responseType).(groupName).metrics = [psthDataGroup.(responseType).(groupName).metrics; metrics];
                
                % Store individual metrics for plotting
                psthDataGroup.(responseType).(groupName).maxFiringRate(end+1) = metrics.maxFiringRate;
                psthDataGroup.(responseType).(groupName).baselineRates(end+1) = metrics.baselineRate;
                psthDataGroup.(responseType).(groupName).treatmentRates(end+1) = unitData.frTreatmentAvg;
                psthDataGroup.(responseType).(groupName).cvValues(end+1) = metrics.cv;
                
                % Store unit info
                unitInfoGroup.(responseType).(groupName){end+1} = struct(...
                    'group', groupName, ...
                    'recording', recordingName, ...
                    'id', unitID);
            end
        end
    end
    
    % Calculate thresholds and identify outliers
    for rType = responseTypes
        for grp = experimentGroups
            if ~isempty(unitInfoGroup.(rType{1}).(grp{1}))
                % Calculate thresholds
                thresholds = calculateGroupThresholds(psthDataGroup.(rType{1}).(grp{1}).metrics);
                groupIQRs.(rType{1}).(grp{1}) = thresholds;
                
                % Flag outliers
                for i = 1:length(unitInfoGroup.(rType{1}).(grp{1}))
                    unitInfo = unitInfoGroup.(rType{1}).(grp{1}){i};
                    metrics = psthDataGroup.(rType{1}).(grp{1}).metrics(i,:);
                    
                    if isUnitOutlier(metrics, thresholds, params)
                        cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = 1;
                        cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).outlierMetrics = metrics;
                    end
                end
            end
        end
    end
    
    % Save results
    if isfield(paths, 'dataFolder') && ~isempty(paths.dataFolder)
        try
            save(fullfile(paths.dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7.3');
            fprintf('Struct saved successfully to: %s\n', paths.dataFolder);
        catch ME
            fprintf('Error saving the file: %s\n', ME.message);
        end
    end
    
    % Optional plotting
    if isfield(paths, 'figureFolder') && ~isempty(paths.figureFolder)
        plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, paths.figureFolder);
    end
end

%% Helper Functions

% Calculate single unit metrics for detecting outlier
function metrics = calculateUnitMetrics(unitData, params)
    % Calculate comprehensive unit metrics
    psth = unitData.psthSmoothed;
    
    % Basic firing rate metrics
    metrics.maxFiringRate = max(psth);
    metrics.meanFiringRate = mean(psth);
    
    % Baseline (using params.preWindow or default to first 10 minutes)
    if isfield(params, 'preWindow')
        baselineIdx = 1:round(params.preWindow(2) / unitData.binWidth);
    else
        baselineIdx = 1:round(10 * 60 / unitData.binWidth);
    end
    metrics.baselineRate = mean(psth(baselineIdx));
    
    % Variability metrics
    metrics.cv = std(psth) / (mean(psth) + eps);
    
    % Burst detection (simplified)
    metrics.burstIndex = sum(diff(psth) > std(psth)) / length(psth);
end

% Label Unit as Outlier
function isOutlier = isUnitOutlier(metrics, thresholds, params)
    % Get outlier threshold from params or use default
    if isfield(params, 'outlierThreshold')
        outlierThreshold = params.outlierThreshold;
    else
        outlierThreshold = 0.33;
    end
    
    % Count how many metrics are outliers
    outlierCount = 0;
    totalMetrics = 0;
    
    for field = fieldnames(metrics)'
        if isfield(thresholds.MetricThresholds, field{1})
            totalMetrics = totalMetrics + 1;
            value = metrics.(field{1});
            thresh = thresholds.MetricThresholds.(field{1});
            if value > thresh.UpperFence || value < thresh.LowerFence
                outlierCount = outlierCount + 1;
            end
        end
    end
    
    % Unit is outlier if more than threshold proportion of metrics are outliers
    isOutlier = (outlierCount / totalMetrics) > outlierThreshold;
end

% Calculate Group Metrics used to label individual outliers
function thresholds = calculateGroupThresholds(groupMetrics)
    % Calculate thresholds for each metric
    thresholds = struct();
    
    for field = fieldnames(groupMetrics)'
        values = groupMetrics.(field{1});
        if ~isempty(values)
            Q1 = prctile(values, 25);
            Q3 = prctile(values, 75);
            IQR = Q3 - Q1;
            
            thresholds.MetricThresholds.(field{1}) = struct(...
                'Q1', Q1, ...
                'Q3', Q3, ...
                'IQR', IQR, ...
                'UpperFence', Q3 + 2 * IQR, ...  % More conservative
                'LowerFence', Q1 - 2 * IQR);     % More conservative
        end
    end
end

% Flag units for processing
function shouldProcess = shouldProcessUnit(unitData, unitFilter)
    % Check if unit should be processed based on filter
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    shouldProcess = ~((strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                     (strcmp(unitFilter, 'multi') && isSingleUnit));
end


