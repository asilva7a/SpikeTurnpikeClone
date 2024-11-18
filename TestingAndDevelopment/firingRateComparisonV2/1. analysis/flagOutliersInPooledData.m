function [cellDataStruct, groupIQRs] = flagOutliersInPooledData(cellDataStruct, params, paths)
    % Input validation
    if nargin < 1 || isempty(cellDataStruct)
        error('cellDataStruct is required');
    end
    
    % Set default parameters if not provided in params
    if ~isfield(params, 'unitFilter')
        params.unitFilter = 'both';
    end
    
    % Get experimental groups from cellDataStruct
    experimentGroups = fieldnames(cellDataStruct);
    if isempty(experimentGroups)
        error('No experimental groups found in cellDataStruct');
    end
    
    % Initialize structures
    groupIQRs = struct();
    psthDataGroup = struct();
    unitInfoGroup = struct();
    
    % Process each unit
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Initialize outlier flag
                cellDataStruct.(groupName).(recordingName).(unitID).isOutlierExperimental = 0;
                
                % Skip if unit shouldn't be processed
                if ~shouldProcessUnit(unitData, params)
                    continue;
                end
                
                % Skip silent/zero units
                if strcmp(unitData.responseType, 'MostlySilent') || ...
                   strcmp(unitData.responseType, 'MostlyZero')
                    continue;
                end
                
                % Calculate and store metrics directly in unit data
                metrics = calculateUnitMetrics(unitData, params);
                cellDataStruct.(groupName).(recordingName).(unitID).metrics = metrics;
            end
        end
    end
    
    % Second pass: Calculate thresholds and identify outliers within each group and response type
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Collect all metrics for this group
        groupMetrics = struct();
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                if isfield(unitData, 'metrics')
                    responseType = matlab.lang.makeValidName(unitData.responseType);
                    if ~isfield(groupMetrics, responseType)
                        groupMetrics.(responseType) = [];
                    end
                    groupMetrics.(responseType) = [groupMetrics.(responseType); ...
                                                 struct2array(unitData.metrics)];
                end
            end
        end
        
        % Calculate thresholds and apply them
        responseTypes = fieldnames(groupMetrics);
        for rt = 1:length(responseTypes)
            responseType = responseTypes{rt};
            if ~isempty(groupMetrics.(responseType))
                thresholds = calculateGroupThresholds(groupMetrics.(responseType));
                
                % Apply thresholds to each unit
                for r = 1:length(recordings)
                    recordingName = recordings{r};
                    units = fieldnames(cellDataStruct.(groupName).(recordingName));
                    
                    for u = 1:length(units)
                        unitID = units{u};
                        unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                        
                        if isfield(unitData, 'metrics')
                            currentResponseType = matlab.lang.makeValidName(unitData.responseType);
                            if strcmp(currentResponseType, responseType)
                                if isUnitOutlier(unitData.metrics, thresholds, params)
                                    cellDataStruct.(groupName).(recordingName).(unitID).isOutlierExperimental = 1;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    % Save results
    if isfield(paths, 'dataFolder') && ~isempty(paths.dataFolder)
        try
            save(fullfile(paths.dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7.3');
            fprintf('Data saved successfully to: %s\n', paths.dataFolder);
        catch ME
            fprintf('Error saving the file: %s\n', ME.message);
        end
    end
end

%% Helper Functions

function metrics = calculateUnitMetrics(unitData, params)
    % Calculate comprehensive unit metrics
    psth = unitData.psthSmoothed;
    
    % Basic firing rate metrics
    metrics.maxFiringRate = max(psth);
    metrics.meanFiringRate = mean(psth);
    
    % Baseline (using params.preWindow)
    baselineIdx = 1:round(params.preWindow(2) / unitData.binWidth);
    metrics.baselineRate = mean(psth(baselineIdx));
    
    % Variability metrics
    metrics.cv = std(psth) / (mean(psth) + eps);
    
    % Burst detection (simplified)
    metrics.burstIndex = sum(diff(psth) > std(psth)) / length(psth);
end

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

function isOutlier = isUnitOutlier(metrics, thresholds, params)
    % Get outlier threshold from params
    outlierThreshold = params.outlierThreshold;
    
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

function shouldProcess = shouldProcessUnit(unitData, params)
    % Check if unit should be processed based on filter
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    shouldProcess = ~((strcmp(params.unitFilter, 'single') && ~isSingleUnit) || ...
                     (strcmp(params.unitFilter, 'multi') && isSingleUnit));
end
