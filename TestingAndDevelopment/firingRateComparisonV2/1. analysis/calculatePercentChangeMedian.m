function cellDataStruct = calculatePercentChangeMedian(cellDataStruct, paths, params, varargin)
    % Parse input parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct', @isstruct);
    addRequired(p, 'paths', @isstruct);
    addRequired(p, 'params', @isstruct);
    
    % Optional parameters with defaults
    addParameter(p, 'baselineWindow', [0, 1800], @(x) isnumeric(x) && length(x)==2);
    addParameter(p, 'postWindow', [2000, 3800], @(x) isnumeric(x) && length(x)==2);
    addParameter(p, 'scalingFactor', 0.5, @isnumeric);
    
    parse(p, cellDataStruct, paths, params, varargin{:});
    opts = p.Results;
    
    % Validate windows relative to treatment time
    if opts.baselineWindow(2) >= params.treatmentTime
        error('Baseline window must end before treatment time');
    end
    if opts.postWindow(1) <= params.treatmentTime
        error('Post window must start after treatment time');
    end
    
    % Process each group
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % First pass: collect all baseline values for the group
        allBaselineValues = [];
        
        % Collect baseline values across all units in the group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Skip invalid units
                if ~isValidUnit(unitData)
                    continue;
                end
                
                % Get baseline values
                binCenters = unitData.binEdges(1:end-1) + unitData.binWidth/2;
                baselineIdx = binCenters >= opts.baselineWindow(1) & binCenters < opts.baselineWindow(2);
                psth = unitData.psthSmoothed;
                validBaselineValues = psth(baselineIdx & psth > 0);
                
                allBaselineValues = [allBaselineValues; validBaselineValues(:)];
            end
        end
        
        % Calculate group baseline median
        groupBaselineMedian = median(allBaselineValues, 'omitnan');
        if isnan(groupBaselineMedian) || groupBaselineMedian == 0
            groupBaselineMedian = opts.scalingFactor;
        end
        
        % Second pass: calculate percent change using group median
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Process units
            numUnits = length(units);
            if numUnits > 100 % Parallel processing for many units
                tempResults = cell(numUnits, 1);
                unitIDs = units;
                unitDataArray = cell(numUnits, 1);
                
                % Extract unit data
                for u = 1:numUnits
                    unitDataArray{u} = cellDataStruct.(groupName).(recordingName).(units{u});
                end
                
                % Process in parallel
                parfor u = 1:numUnits
                    tempResults{u} = processUnit(unitDataArray{u}, opts.baselineWindow, ...
                        opts.postWindow, opts.scalingFactor, groupBaselineMedian);
                end
                
                % Update structure
                for u = 1:numUnits
                    if ~isempty(tempResults{u})
                        cellDataStruct.(groupName).(recordingName).(unitIDs{u}) = tempResults{u};
                    end
                end
            else
                % Serial processing
                for u = 1:length(units)
                    unitID = units{u};
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    processedData = processUnit(unitData, opts.baselineWindow, ...
                        opts.postWindow, opts.scalingFactor, groupBaselineMedian);
                    if ~isempty(processedData)
                        cellDataStruct.(groupName).(recordingName).(unitID) = processedData;
                    end
                end
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
        'median', median(data, 'omitnan'), ...
        'stdDev', std(data, 'omitnan'), ...
        'range', range(data), ...
        'var', var(data, 'omitnan'));
end

function unitData = processUnit(unitData, baselineWindow, postWindow, SCALING_FACTOR, groupBaselineMedian)
    % Input validation
    if ~isValidUnit(unitData)
        return;
    end
    
    % Get time vectors
    binCenters = unitData.binEdges(1:end-1) + unitData.binWidth/2;
    
    % Get indices
    baselineIdx = binCenters >= baselineWindow(1) & binCenters < baselineWindow(2);
    postIdx = binCenters >= postWindow(1) & binCenters < postWindow(2);
    
    % Calculate percent change using group baseline median
    psth = unitData.psthSmoothed;
    psthPercentChange = ((psth - groupBaselineMedian) / groupBaselineMedian) * 100;
    
    % Calculate statistics efficiently
    stats = struct();
    stats.baseline = getStats(psth(baselineIdx));
    stats.postTreatment = getStats(psth(postIdx));
    stats.baseline.median = groupBaselineMedian;  % Store group median
    
    % Add average firing rates if available
    if isfield(unitData, 'frBaselineAvg')
        stats.baseline.frAvg = unitData.frBaselineAvg;
    end
    if isfield(unitData, 'frTreatmentAvg')
        stats.postTreatment.frAvg = unitData.frTreatmentAvg;
    end
    
    % Update unit data
    unitData.psthPercentChange = psthPercentChange;
    unitData.psthPercentChangeStats = stats;
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
