function [cellDataStruct, groupIQRs] = flagOutliersInPooledData(cellDataStruct, unitFilter, figureFolder, dataFolder)
    % Set default arguments
    if nargin < 2 || isempty(unitFilter)
        unitFilter = 'both'; % Default to processing both single and multi units
    end
    
    % Input validation
    if nargin < 1 || isempty(cellDataStruct)
        error('cellDataStruct is required');
    end
    
    % Define response types and groups
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    experimentGroups = {'Emx', 'Pvalb', 'Control'};
    
    % Initialize structures
    groupIQRs = struct();
    psthDataGroup = struct();
    unitInfoGroup = struct();
    
    % Initialize metrics structure for each response type and group
    for rType = responseTypes
        psthDataGroup.(rType{1}) = struct();
        unitInfoGroup.(rType{1}) = struct();
        groupIQRs.(rType{1}) = struct();
        
        % Initialize for each experimental group
        for expGroup = experimentGroups
            % Initialize psthDataGroup fields
            psthDataGroup.(rType{1}).(expGroup{1}) = struct(...
                'maxFiringRate', [], ...
                'baselineRate', [], ...
                'treatmentRate', [], ...
                'cv', [], ...
                'baselineCV', [], ...
                'treatmentCV', [], ...
                'baselinePeakRatio', [], ...
                'treatmentPeakRatio', [], ...
                'burstIndex', [], ...
                'isHighFiring', [], ...
                'isUnstable', [], ...
                'metrics', []);
            
            % Initialize unitInfoGroup as empty cell array
            unitInfoGroup.(rType{1}).(expGroup{1}) = {};
            
            % Initialize groupIQRs fields
            groupIQRs.(rType{1}).(expGroup{1}) = struct(...
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
                
                % Use helper function to check if unit should be processed
                if ~shouldProcessUnit(unitData, unitFilter)
                    continue;
                end
                
                % Get response type
                responseType = replace(unitData.responseType, ' ', '');
                if strcmp(responseType, 'MostlySilent') || strcmp(responseType, 'MostlyZero')
                    continue;
                end
                
                % Use helper function to calculate metrics
                metrics = calculateUnitMetrics(unitData);
                
                % Store metrics and individual values
                if ~isfield(psthDataGroup.(responseType).(groupName), 'metrics')
                    psthDataGroup.(responseType).(groupName).metrics = [];
                end
                psthDataGroup.(responseType).(groupName).metrics = [psthDataGroup.(responseType).(groupName).metrics; metrics];
                
                % Store individual metrics for plotting
                psthDataGroup.(responseType).(groupName).maxFiringRate(end+1) = metrics.maxFiringRate;
                psthDataGroup.(responseType).(groupName).baselineRate(end+1) = metrics.baselineRate;
                psthDataGroup.(responseType).(groupName).treatmentRate(end+1) = metrics.treatmentRate;
                psthDataGroup.(responseType).(groupName).cv(end+1) = metrics.cv;
                psthDataGroup.(responseType).(groupName).baselineCV(end+1) = metrics.baselineCV;
                psthDataGroup.(responseType).(groupName).treatmentCV(end+1) = metrics.treatmentCV;
                psthDataGroup.(responseType).(groupName).baselinePeakRatio(end+1) = metrics.baselinePeakRatio;
                psthDataGroup.(responseType).(groupName).treatmentPeakRatio(end+1) = metrics.treatmentPeakRatio;
                psthDataGroup.(responseType).(groupName).burstIndex(end+1) = metrics.burstIndex;
                psthDataGroup.(responseType).(groupName).isHighFiring(end+1) = metrics.isHighFiring;
                psthDataGroup.(responseType).(groupName).isUnstable(end+1) = metrics.isUnstable;
                
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
                    metrics = psthDataGroup.(rType{1}).(grp{1}).metrics(i);
                    
                    % Pass response type and group name to isUnitOutlier
                    if isUnitOutlier(metrics, thresholds, rType{1}, grp{1})
                        cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = 1;
                        cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).outlierMetrics = metrics;
                    end
                end
            end
        end
    end

    
    % Save results
    if nargin >= 4 && ~isempty(dataFolder)
        try
            save(fullfile(dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7.3');
            fprintf('Struct saved successfully to: %s\n', dataFolder);
        catch ME
            fprintf('Error saving the file: %s\n', ME.message);
        end
    end
    
    % Optional plotting
    if nargin > 2 && ~isempty(figureFolder)
        plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, figureFolder);
    end
end

function metrics = calculateUnitMetrics(unitData)
    % Get PSTH and time vector
    psth = unitData.psthSmoothed;
    timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
    
    % Define analysis windows
    baselineIdx = timeVector >= 300 & timeVector <= 1860;  % 5-31 minutes
    treatmentIdx = timeVector > 1860 & timeVector <= 3420; % 31-57 minutes
    
    % Basic firing rate metrics
    metrics.maxFiringRate = max(psth);
    metrics.meanFiringRate = mean(psth);
    metrics.baselineRate = mean(psth(baselineIdx));
    metrics.treatmentRate = mean(psth(treatmentIdx));
    
    % Variability metrics
    metrics.baselineCV = std(psth(baselineIdx)) / (mean(psth(baselineIdx)) + eps);
    metrics.treatmentCV = std(psth(treatmentIdx)) / (mean(psth(treatmentIdx)) + eps);
    metrics.cv = std(psth) / (mean(psth) + eps);
    
    % Peak-to-mean ratios
    metrics.baselinePeakRatio = max(psth(baselineIdx)) / (metrics.baselineRate + eps);
    metrics.treatmentPeakRatio = max(psth(treatmentIdx)) / (metrics.treatmentRate + eps);
    
    % Burst detection
    metrics.burstIndex = sum(diff(psth) > std(psth)) / length(psth);
    
    % Thresholds
    metrics.isHighFiring = max(psth) > 10;
    metrics.isUnstable = metrics.cv > 1.5;
end

function shouldProcess = shouldProcessUnit(unitData, unitFilter)
    % Check if unit should be processed based on filter
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    shouldProcess = ~((strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                     (strcmp(unitFilter, 'multi') && isSingleUnit));
end

function isOutlier = isUnitOutlier(metrics, thresholds, responseType, groupName)
    % Initialize output
    isOutlier = false;
    
    % Set thresholds based on response type and group
    switch responseType
        case 'Increased'
            switch groupName
                case 'Emx'
                    maxRate = 60;  % Box plot shows outliers up to ~60Hz
                    maxCV = 2.5;   % Allow higher variability for increased units
                case 'Pvalb'
                    maxRate = 25;  % Box plot shows outliers ~20-25Hz
                    maxCV = 2.0;   % Lower variability threshold for Pvalb
                otherwise  % Control
                    maxRate = 25;  % Similar to Pvalb threshold
                    maxCV = 2.0;
            end
            
        case 'Decreased'
            switch groupName
                case 'Emx'
                    maxRate = 10;  % Box plot shows outliers ~9Hz
                    maxCV = 1.5;
                case 'Pvalb'
                    maxRate = 4;   % Tighter distribution shown
                    maxCV = 1.5;
                otherwise  % Control
                    maxRate = 15;  % Box plot shows higher variability
                    maxCV = 1.8;
            end
            
        case 'NoChange'
            switch groupName
                case 'Emx'
                    maxRate = 3;   % Tighter distribution in box plot
                    maxCV = 1.2;
                case 'Pvalb'
                    maxRate = 15;  % Box plot shows outliers up to ~13Hz
                    maxCV = 1.8;   % Allow more variability based on time series
                otherwise  % Control
                    maxRate = 5;
                    maxCV = 1.5;
            end
    end
    
    % Check for extreme firing rates
    if metrics.baselineRate > maxRate || metrics.treatmentRate > maxRate
        isOutlier = true;
        return;
    end
    
    % Check for unstable baseline
    if metrics.baselineCV > maxCV
        isOutlier = true;
        return;
    end
    
    % Check for extreme peaks relative to mean
    peakRatioThreshold = thresholds.Overall.MaxPeakRatio;
    if metrics.baselinePeakRatio > peakRatioThreshold || ...
       metrics.treatmentPeakRatio > peakRatioThreshold
        isOutlier = true;
        return;
    end
    
    % Check overall variability
    if metrics.cv > maxCV
        isOutlier = true;
        return;
    end
end

function thresholds = calculateGroupThresholds(groupMetrics)
    % Initialize thresholds structure
    thresholds = struct();
    
    % Get field names from the metrics structure
    metricFields = fieldnames(groupMetrics);
    
    % Calculate thresholds for each metric
    for i = 1:length(metricFields)
        field = metricFields{i};
        values = [groupMetrics.(field)];  % Convert to array
        
        if ~isempty(values)
            % Calculate quartiles and IQR
            Q1 = prctile(values, 25);
            Q3 = prctile(values, 75);
            IQR = Q3 - Q1;
            median_val = median(values);
            
            % Store thresholds for this metric
            thresholds.MetricThresholds.(field).Q1 = Q1;
            thresholds.MetricThresholds.(field).Q3 = Q3;
            thresholds.MetricThresholds.(field).IQR = IQR;
            thresholds.MetricThresholds.(field).Median = median_val;
            thresholds.MetricThresholds.(field).UpperFence = Q3 + 2 * IQR;
            thresholds.MetricThresholds.(field).LowerFence = Q1 - 2 * IQR;
        end
    end
    
    % Add overall thresholds
    thresholds.Overall.MaxFiringRate = 10;
    thresholds.Overall.MinFiringRate = 0.01;
    thresholds.Overall.MaxCV = 1.5;
    thresholds.Overall.MaxPeakRatio = 5;
end


