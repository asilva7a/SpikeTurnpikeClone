function cellDataStruct = calculateZScoreGroupMean(cellDataStruct, paths, params, varargin)
    % Parse input parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct', @isstruct);
    addRequired(p, 'paths', @isstruct);
    addRequired(p, 'params', @isstruct);
    
    % Optional parameters with defaults
    addParameter(p, 'baselineWindow', [0, 1860], @(x) isnumeric(x) && length(x)==2); % Full pre-treatment period
    addParameter(p, 'postWindow', [2000, 5000], @(x) isnumeric(x) && length(x)==2);
    addParameter(p, 'scalingFactor', 0.5, @isnumeric);
    
    parse(p, cellDataStruct, paths, params, varargin{:});
    opts = p.Results;
    
    % Process each group
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % First pass: collect all pre-treatment values for the group
        allPreTreatmentValues = [];
        
        % Collect pre-treatment values across all units in the group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                if ~isValidUnit(unitData)
                    continue;
                end
                
                % Get pre-treatment values
                binCenters = unitData.binEdges(1:end-1) + unitData.binWidth/2;
                preTreatmentIdx = binCenters < params.treatmentTime;
                psth = unitData.psthSmoothed;
                preTreatmentValues = psth(preTreatmentIdx);
                
                allPreTreatmentValues = [allPreTreatmentValues; preTreatmentValues(:)];
            end
        end
        
        % Calculate group pre-treatment statistics
        groupPreTreatmentMean = mean(allPreTreatmentValues, 'omitnan');
        groupPreTreatmentStd = std(allPreTreatmentValues, 'omitnan');
        
        % Handle edge cases
        if isnan(groupPreTreatmentMean) || groupPreTreatmentMean == 0
            groupPreTreatmentMean = opts.scalingFactor;
        end
        if isnan(groupPreTreatmentStd) || groupPreTreatmentStd == 0
            groupPreTreatmentStd = 1.0;
        end
        
        % Second pass: calculate z-scores using pre-treatment statistics
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                if ~isValidUnit(unitData)
                    continue;
                end
                
                % Calculate z-score using pre-treatment statistics
                psth = unitData.psthSmoothed;
                psthZScore = (psth - groupPreTreatmentMean) / groupPreTreatmentStd;
                
                % Calculate statistics
                binCenters = unitData.binEdges(1:end-1) + unitData.binWidth/2;
                baselineIdx = binCenters >= opts.baselineWindow(1) & binCenters < opts.baselineWindow(2);
                postIdx = binCenters >= opts.postWindow(1) & binCenters < opts.postWindow(2);
                
                stats = struct();
                stats.baseline = getStats(psth(baselineIdx));
                stats.postTreatment = getStats(psth(postIdx));
                stats.preTreatment.mean = groupPreTreatmentMean;
                stats.preTreatment.std = groupPreTreatmentStd;
                
                % Update unit data
                unitData.psthZScore = psthZScore;
                unitData.psthZScoreStats = stats;
                cellDataStruct.(groupName).(recordingName).(unitID) = unitData;
            end
        end
    end
    
    % Save results
    try
        save(paths.cellDataStructPath, 'cellDataStruct', '-v7.3', '-nocompression');
        fprintf('Data saved successfully to: %s\n', paths.cellDataStructPath);
    catch ME
        fprintf('Error saving data: %s\n', ME.message);
    end
end

function stats = getStats(data)
    % Efficient statistics calculation
    stats = struct(...
        'mean', mean(data, 'omitnan'), ...
        'std', std(data, 'omitnan'), ...
        'range', range(data), ...
        'var', var(data, 'omitnan'));
end

function isValid = isValidUnit(unitData)
    % Validation helper function
    isValid = ~(isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental) && ...
              isfield(unitData, 'psthSmoothed') && ...
              isfield(unitData, 'binEdges') && ...
              isfield(unitData, 'binWidth') && ...
              isfield(unitData, 'responseType') && ...
              ~strcmp(unitData.responseType, 'MostlySilent') && ...
              ~strcmp(unitData.responseType, 'MostlyZero') && ...
              length(unitData.psthSmoothed) == length(unitData.binEdges)-1;
end
