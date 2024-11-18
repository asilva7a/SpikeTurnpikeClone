function [cellDataStruct, groupIQRs] = flagOutliersInPooledData(cellDataStruct, params, paths)
    % Input validation
    if nargin < 1 || isempty(cellDataStruct)
        error('cellDataStruct is required');
    end
    
    % Debug: Print input parameters
    fprintf('Starting flagOutliersInPooledData with:\n');
    if isfield(params, 'unitFilter')
        fprintf('Unit filter: %s\n', params.unitFilter);
    end
    if isfield(params, 'analysis') && isfield(params.analysis, 'preWindow')
        fprintf('Pre-window: [%g, %g]\n', params.analysis.preWindow(1), params.analysis.preWindow(2));
    end
    
    % Set default parameters if not provided
    if ~isfield(params, 'unitFilter')
        params.unitFilter = 'both';
        fprintf('Using default unit filter: both\n');
    end
    if ~isfield(params, 'analysis')
        params.analysis = struct();
    end
    if ~isfield(params.analysis, 'outlierThreshold')
        params.analysis.outlierThreshold = 0.33;
        fprintf('Using default outlier threshold: 0.33\n');
    end
    
    % Get experimental groups from cellDataStruct
    experimentGroups = fieldnames(cellDataStruct);
    if isempty(experimentGroups)
        error('No experimental groups found in cellDataStruct');
    end
    fprintf('Found experimental groups: %s\n', strjoin(experimentGroups, ', '));
    
    % Initialize structures
    groupIQRs = struct();
    psthDataGroup = struct();
    unitInfoGroup = struct();
    
    % Process each unit
    fprintf('\nProcessing units...\n');
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        fprintf('\nProcessing group: %s\n', groupName);
        
        recordings = fieldnames(cellDataStruct.(groupName));
        fprintf('Found %d recordings\n', length(recordings));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            fprintf('Processing recording %s with %d units\n', recordingName, length(units));
            
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
                if ~isfield(unitData, 'responseType')
                    fprintf('Warning: No responseType field for unit %s\n', unitID);
                    continue;
                end
                
                % Get response type and ensure it's a valid field name
                try
                    if ~isfield(unitData, 'responseType')
                        fprintf('Warning: No responseType field for unit %s\n', unitID);
                        continue;
                    end
                        
                    responseType = unitData.responseType;
                    fprintf('Debug - Raw response type for unit %s: %s (class: %s)\n', ...
                        unitID, responseType, class(responseType));

                    if isnumeric(responseType)
                        responseType = sprintf('Type_%d', responseType);
                    elseif ~ischar(responseType) && ~isstring(responseType)
                        fprintf('Warning: Invalid response type format for unit %s\n', unitID);
                        continue;
                    end

                    responseType = strrep(responseType, ' ', '_');
                    responseType = strrep(responseType, '-', '_');

                    % Ensure valid field name
                    responseType = matlab.lang.makeValidName(responseType);
                    fprintf('Debug - Processed response type: %s\n', responseType);
                    
                    % Debug output
                    fprintf('Processing unit %s with response type: %s\n', unitID, responseType);
                    
                    if strcmp(responseType, 'MostlySilent') || strcmp(responseType, 'MostlyZero')
                        continue;
                    end
                    
                    % Calculate metrics
                    metrics = calculateUnitMetrics(unitData, params);
                    
                    % Initialize response type structures if needed
                    if ~isfield(psthDataGroup, responseType)
                        psthDataGroup.(responseType) = struct();
                        unitInfoGroup.(responseType) = struct();
                        groupIQRs.(responseType) = struct();
                    end
                    
                    if ~isfield(psthDataGroup.(responseType), groupName)
                        psthDataGroup.(responseType).(groupName) = struct(...
                            'maxFiringRate', [], ...
                            'baselineRates', [], ...
                            'treatmentRates', [], ...
                            'cvValues', [], ...
                            'metrics', []);
                        unitInfoGroup.(responseType).(groupName) = {};
                        groupIQRs.(responseType).(groupName) = struct(...
                            'IQR', [], ...
                            'Median', [], ...
                            'UpperFence', [], ...
                            'LowerFence', []);
                    end
                    
                    % Store metrics
                    psthDataGroup.(responseType).(groupName).metrics = [psthDataGroup.(responseType).(groupName).metrics; struct2array(metrics)];
                    psthDataGroup.(responseType).(groupName).maxFiringRate(end+1) = metrics.maxFiringRate;
                    psthDataGroup.(responseType).(groupName).baselineRates(end+1) = metrics.baselineRate;
                    psthDataGroup.(responseType).(groupName).treatmentRates(end+1) = unitData.frTreatmentAvg;
                    psthDataGroup.(responseType).(groupName).cvValues(end+1) = metrics.cv;
                    
                    % Store unit info
                    unitInfoGroup.(responseType).(groupName){end+1} = struct(...
                        'group', groupName, ...
                        'recording', recordingName, ...
                        'id', unitID);
                catch ME
                    fprintf('Error processing unit %s: %s\n', unitID, ME.message);
                    continue;
                end
            end
        end
    end
    
    % Calculate thresholds and identify outliers
    fprintf('\nCalculating thresholds and identifying outliers...\n');
    responseTypes = fieldnames(psthDataGroup);
    for rt = 1:length(responseTypes)
        responseType = responseTypes{rt};
        fprintf('Processing response type: %s\n', responseType);
        
        for g = 1:length(experimentGroups)
            groupName = experimentGroups{g};
            
            if isfield(unitInfoGroup.(responseType), groupName) && ...
               ~isempty(unitInfoGroup.(responseType).(groupName))
                try
                    % Calculate thresholds
                    thresholds = calculateGroupThresholds(psthDataGroup.(responseType).(groupName).metrics);
                    groupIQRs.(responseType).(groupName) = thresholds;
                    
                    % Flag outliers
                    for i = 1:length(unitInfoGroup.(responseType).(groupName))
                        unitInfo = unitInfoGroup.(responseType).(groupName){i};
                        metrics = psthDataGroup.(responseType).(groupName).metrics(i,:);
                        
                        if isUnitOutlier(metrics, thresholds, params)
                            cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = 1;
                            cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).outlierMetrics = metrics;
                        end
                    end
                catch ME
                    fprintf('Error processing group %s: %s\n', groupName, ME.message);
                    continue;
                end
            end
        end
    end
    
    % Save results
    if isfield(paths, 'output') && isfield(paths.output, 'dataFolder') && ...
       ~isempty(paths.output.dataFolder)
        try
            save(fullfile(paths.output.dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7.3');
            fprintf('Data saved successfully to: %s\n', paths.output.dataFolder);
        catch ME
            fprintf('Error saving data: %s\n', ME.message);
        end
    end
end

%% Helper Functions remain unchanged except for params usage

function metrics = calculateUnitMetrics(unitData, params)
    % Calculate comprehensive unit metrics
    psth = unitData.psthSmoothed;
    
    % Basic firing rate metrics
    metrics.maxFiringRate = max(psth);
    metrics.meanFiringRate = mean(psth);
    
    % Baseline using params.analysis.preWindow
    if isfield(params, 'analysis') && isfield(params.analysis, 'preWindow')
        baselineIdx = 1:round(params.analysis.preWindow(2) / unitData.binWidth);
    else
        baselineIdx = 1:round(10 * 60 / unitData.binWidth);
    end
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
    if isfield(params, 'analysis') && isfield(params.analysis, 'outlierThreshold')
        outlierThreshold = params.analysis.outlierThreshold;
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

function shouldProcess = shouldProcessUnit(unitData, params)
    % Check if unit should be processed based on filter
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    shouldProcess = ~((strcmp(params.unitFilter, 'single') && ~isSingleUnit) || ...
                     (strcmp(params.unitFilter, 'multi') && isSingleUnit));
end
