function cellDataStruct = calculatePercentChangeMean(cellDataStruct, paths, params, varargin)
    % Parse input parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct', @isstruct);
    addRequired(p, 'paths', @isstruct);
    addRequired(p, 'params', @isstruct);
    
    % Optional parameters with defaults
    addParameter(p, 'baselineWindow', [300, 1800], @(x) isnumeric(x) && length(x)==2);
    addParameter(p, 'postWindow', [2000, 3500], @(x) isnumeric(x) && length(x)==2);
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
    
    % Process each unit
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Pre-allocate cell array for parallel processing if needed
            numUnits = length(units);
            if numUnits > 100 % Only use parallel if many units
                tempResults = cell(numUnits, 1);
                unitIDs = units;
                unitDataArray = cell(numUnits, 1);
                
                % Extract unit data for parallel processing
                for u = 1:numUnits
                    unitDataArray{u} = cellDataStruct.(groupName).(recordingName).(units{u});
                end
                
                % Process in parallel
                parfor u = 1:numUnits
                    tempResults{u} = processUnit(unitDataArray{u}, opts.baselineWindow, ...
                        opts.postWindow, opts.scalingFactor);
                end
                
                % Update structure after parallel loop
                for u = 1:numUnits
                    if ~isempty(tempResults{u})
                        cellDataStruct.(groupName).(recordingName).(unitIDs{u}) = tempResults{u};
                    end
                end
            else
                % Original serial processing code
                for u = 1:numUnits
                    unitID = units{u};
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    % Process unit directly
                    processedData = processUnit(unitData, opts.baselineWindow, ...
                        opts.postWindow, opts.scalingFactor);
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
        'mean', mean(data, 'omitnan'), ...
        'stdDev', std(data, 'omitnan'), ...
        'range', range(data), ...
        'var', var(data, 'omitnan'));
end

function unitData = processUnit(unitData, baselineWindow, postWindow, SCALING_FACTOR)
    % Input validation
    if (isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental) || ...
       ~isfield(unitData, 'psthSmoothed') || ~isfield(unitData, 'binEdges') || ...
       ~isfield(unitData, 'binWidth') || ~isfield(unitData, 'responseType') || ...
       strcmp(unitData.responseType, 'MostlySilent') || ...
       strcmp(unitData.responseType, 'MostlyZero')
        return;
    end
    
    % Validate data dimensions
    if length(unitData.psthSmoothed) ~= length(unitData.binEdges)-1
        warning('PSTH length does not match bin edges');
        return;
    end
    
    % Get time vectors
    binCenters = unitData.binEdges(1:end-1) + unitData.binWidth/2;
    
    % Get indices
    baselineIdx = binCenters >= baselineWindow(1) & binCenters < baselineWindow(2);
    postIdx = binCenters >= postWindow(1) & binCenters < postWindow(2);
    
    % Calculate baseline mean (only for non-zero values)
    psth = unitData.psthSmoothed;
    baselineMean = mean(psth(baselineIdx & psth > 0), 'omitnan');
    
    % Calculate percent change
    if isnan(baselineMean) || baselineMean == 0
        baselineMean = SCALING_FACTOR;
        psthPercentChange = (((psth + SCALING_FACTOR) - SCALING_FACTOR) / SCALING_FACTOR) * 100;
    else
        psthPercentChange = ((psth - baselineMean) / baselineMean) * 100;
    end
    
    % Calculate statistics efficiently
    stats = struct();
    stats.baseline = getStats(psth(baselineIdx));
    stats.postTreatment = getStats(psth(postIdx));
    stats.baseline.mean = baselineMean;
    
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
