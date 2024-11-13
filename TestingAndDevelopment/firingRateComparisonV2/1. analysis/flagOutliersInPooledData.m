function [cellDataStruct, groupIQRs] = flagOutliersInPooledData(cellDataStruct, unitFilter, figureFolder, dataFolder)
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
        
        for grp = experimentGroups
            psthDataGroup.(rType{1}).(grp{1}) = struct(...
                'maxFiringRate', [], ...
                'baselineRates', [], ...
                'treatmentRates', [], ...
                'cvValues', []);
            
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
                
                % Check required fields
                if ~isfield(unitData, 'responseType') || ...
                   ~isfield(unitData, 'psthSmoothed') || ...
                   ~isfield(unitData, 'frBaselineAvg') || ...
                   ~isfield(unitData, 'frTreatmentAvg')
                    continue;
                end
                
                % Get response type
                responseType = replace(unitData.responseType, ' ', '');
                if strcmp(responseType, 'MostlySilent') || strcmp(responseType, 'MostlyZero')
                    continue;
                end
                
                % Apply unit filter
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if (strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                   (strcmp(unitFilter, 'multi') && isSingleUnit)
                    continue;
                end
                
                % Calculate metrics
                maxFiringRate = max(unitData.psthSmoothed);
                baselineRate = unitData.frBaselineAvg;
                treatmentRate = unitData.frTreatmentAvg;
                cv = std(unitData.psthSmoothed) / (mean(unitData.psthSmoothed) + eps);
                
                % Store metrics
                psthDataGroup.(responseType).(groupName).maxFiringRate(end+1) = maxFiringRate;
                psthDataGroup.(responseType).(groupName).baselineRates(end+1) = baselineRate;
                psthDataGroup.(responseType).(groupName).treatmentRates(end+1) = treatmentRate;
                psthDataGroup.(responseType).(groupName).cvValues(end+1) = cv;
                
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
                % Calculate IQR thresholds
                maxRates = psthDataGroup.(rType{1}).(grp{1}).maxFiringRate;
                Q1 = prctile(maxRates, 25);
                Q3 = prctile(maxRates, 75);
                IQR = Q3 - Q1;
                upperFence = Q3 + 1.5 * IQR;
                lowerFence = Q1 - 1.5 * IQR;
                
                % Store thresholds
                groupIQRs.(rType{1}).(grp{1}).IQR = IQR;
                groupIQRs.(rType{1}).(grp{1}).Median = median(maxRates);
                groupIQRs.(rType{1}).(grp{1}).UpperFence = upperFence;
                groupIQRs.(rType{1}).(grp{1}).LowerFence = lowerFence;
                
                % Flag outliers
                for i = 1:length(unitInfoGroup.(rType{1}).(grp{1}))
                    unitInfo = unitInfoGroup.(rType{1}).(grp{1}){i};
                    
                    % Get metrics for this unit
                    maxFiringRate = psthDataGroup.(rType{1}).(grp{1}).maxFiringRate(i);
                    baselineRate = psthDataGroup.(rType{1}).(grp{1}).baselineRates(i);
                    treatmentRate = psthDataGroup.(rType{1}).(grp{1}).treatmentRates(i);
                    cv = psthDataGroup.(rType{1}).(grp{1}).cvValues(i);
                    
                    % Calculate outlier score
                    outlierScore = 0;
                    
                    % Check max firing rate
                    if maxFiringRate > upperFence || maxFiringRate < lowerFence
                        outlierScore = outlierScore + 1;
                    end
                    
                    % Check baseline to treatment change
                    rateChange = abs(treatmentRate - baselineRate) / (baselineRate + eps);
                    if rateChange > median(abs(diff([baselineRate, treatmentRate]))) + ...
                       2 * std(abs(diff([baselineRate, treatmentRate])))
                        outlierScore = outlierScore + 1;
                    end
                    
                    % Check variability
                    if cv > median(psthDataGroup.(rType{1}).(grp{1}).cvValues) + ...
                       2 * std(psthDataGroup.(rType{1}).(grp{1}).cvValues)
                        outlierScore = outlierScore + 1;
                    end
                    
                    % Flag unit if multiple criteria are met
                    if outlierScore >= 2
                        cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = 1;
                        cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).outlierMetrics = struct(...
                            'maxFiringRate', maxFiringRate, ...
                            'baselineRate', baselineRate, ...
                            'treatmentRate', treatmentRate, ...
                            'cv', cv, ...
                            'outlierScore', outlierScore);
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
        plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, groupIQRs, figureFolder);
    end
end


function metrics = calculateUnitMetrics(unitData)
    % Calculate comprehensive unit metrics
    psth = unitData.psthSmoothed;
    
    % Basic firing rate metrics
    metrics.maxFiringRate = max(psth);
    metrics.meanFiringRate = mean(psth);
    
    % Baseline (first 10 minutes)
    baselineIdx = 1:round(10 * 60 / unitData.binWidth);
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

function isOutlier = isUnitOutlier(metrics, thresholds)
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
    
    % Unit is outlier if more than 1/3 of metrics are outliers
    isOutlier = (outlierCount / totalMetrics) > 0.33;
end

function shouldProcess = shouldProcessUnit(unitData, unitFilter)
    % Check if unit should be processed based on filter
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    shouldProcess = ~((strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                     (strcmp(unitFilter, 'multi') && isSingleUnit));
end


