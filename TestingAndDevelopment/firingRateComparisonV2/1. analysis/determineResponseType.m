function cellDataStruct = determineResponseType(cellDataStruct, paths, params, varargin)
    % Parse input parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct', @isstruct);
    addRequired(p, 'paths', @isstruct);
    addRequired(p, 'params', @isstruct);
    
    % Optional parameters with defaults
    addParameter(p, 'tagSparse', false, @islogical);
    addParameter(p, 'preWindow', [0, 1800], @(x) isnumeric(x) && length(x) == 2);
    addParameter(p, 'postWindow', [2000, 3800], @(x) isnumeric(x) && length(x) == 2);
    addParameter(p, 'silenceThreshold', 0.0001, @isnumeric);
    addParameter(p, 'silenceScoreThreshold', 0.95, @isnumeric);
    
    % Parse inputs
    parse(p, cellDataStruct, paths, params, varargin{:});
    opts = p.Results;
    
    % Process each group
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            numUnits = length(units);
            
            if numUnits > 100  % Only use parallel for many units
                % Pre-allocate cell arrays
                unitResults = cell(numUnits, 1);
                unitData = cell(numUnits, 1);
                
                % Extract unit data for parallel processing
                for u = 1:numUnits
                    unitData{u} = cellDataStruct.(groupName).(recordingName).(units{u});
                end
                
                % Process units in parallel
                parfor u = 1:numUnits
                    unitResults{u} = processUnit(unitData{u}, opts.preWindow, opts.postWindow, ...
                                              opts.silenceThreshold, opts.silenceScoreThreshold, ...
                                              params.binWidth);
                end
                
                    % Update cellDataStruct
                    for u = 1:numUnits
                        if ~isempty(unitResults{u})
                            cellDataStruct.(groupName).(recordingName).(units{u}) = unitResults{u};
                        end
                    end
                else
                % Process units serially
                for u = 1:numUnits
                    unitID = units{u};
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    processedUnit = processUnit(unitData, opts.preWindow, opts.postWindow, ...
                                             opts.silenceThreshold, opts.silenceScoreThreshold, ...
                                             params.binWidth);
                    if ~isempty(processedUnit)
                        cellDataStruct.(groupName).(recordingName).(unitID) = processedUnit;
                    end
                end
            end
        end
    end
    
    % Optional: Run sparse unit detection
    if opts.tagSparse
        try
            [cellDataStruct, ~] = tagSparseUnits(cellDataStruct, params.binWidth, 0.5, paths.frTreatmentDir);
        catch ME
            fprintf('Error in sparse unit detection: %s\n', ME.message);
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


function unitData = processUnit(unitData, preWindow, postWindow, silenceThreshold, silenceScoreThreshold, binWidth)
    % Skip processing if required fields are missing
    if ~isfield(unitData, 'psthSmoothed') || ~isfield(unitData, 'binEdges') || ...
       ~isfield(unitData, 'binWidth')
        return;
    end
    
    % Initialize flags
    unitData.unitFlags = struct('isMostlySilent', false, ...
                               'isMostlyZero', false, ...
                               'isDataMissing', false);
    
    % Get time vectors and indices
    timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
    preIndices = timeVector >= preWindow(1) & timeVector <= preWindow(2);
    postIndices = timeVector >= postWindow(1) & timeVector <= postWindow(2);
    
    % Get firing rates
    frBefore = unitData.psthSmoothed(preIndices);
    frAfter = unitData.psthSmoothed(postIndices);
    
    % Check data validity
    if isempty(frBefore) || isempty(frAfter) || length(frBefore) ~= length(frAfter)
        unitData.unitFlags.isDataMissing = true;
        unitData.responseType = 'Missing Data';
        return;
    end
    
    % Calculate comprehensive statistics
    stats = calculateResponseStats(frBefore, frAfter, binWidth);
    
    % Calculate silence scores
    silenceScoreBefore = mean(frBefore < silenceThreshold);
    silenceScoreAfter = mean(frAfter < silenceThreshold);
    unitData.unitFlags.isMostlySilent = (silenceScoreBefore >= silenceScoreThreshold || ...
                                        silenceScoreAfter >= silenceScoreThreshold);
    
    % Determine response type using enhanced criteria
    [responseType, responseMetrics] = classifyResponse(stats);
    
    % Store results
    unitData.pValue = stats.p_value;
    unitData.responseType = responseType;
    unitData.responseMetrics = responseMetrics;
    unitData.stats = stats;
end

function stats = calculateResponseStats(preRate, postRate, binWidth)
    % Calculate comprehensive statistics
    stats = struct();
    
    % Basic statistics
    stats.mean_pre = mean(preRate, 'omitnan');
    stats.mean_post = mean(postRate, 'omitnan');
    stats.std_pre = std(preRate, 'omitnan');
    stats.std_post = std(postRate, 'omitnan');
    
    % Effect size (Cohen's d)
    pooled_std = sqrt((var(preRate, 'omitnan') + var(postRate, 'omitnan'))/2);
    stats.cohens_d = (stats.mean_post - stats.mean_pre) / pooled_std;
    
    % Wilcoxon signed rank test
    [stats.p_value, stats.h_wilcox] = signrank(preRate, postRate, 'alpha', 0.01);
    
    % Bootstrap confidence intervals
    nBootstraps = 1000;
    bootstat_pre = bootstrp(nBootstraps, @mean, preRate);
    bootstat_post = bootstrp(nBootstraps, @mean, postRate);
    stats.ci_pre = prctile(bootstat_pre, [2.5 97.5]);
    stats.ci_post = prctile(bootstat_post, [2.5 97.5]);
    
    % Percent change
    stats.percent_change = ((stats.mean_post - stats.mean_pre) / stats.mean_pre) * 100;
    
    % Signal-to-Noise Ratio
    stats.snr = abs(stats.mean_post - stats.mean_pre) / ...
                sqrt(stats.std_pre^2 + stats.std_post^2);
    
    % Reliability score (combines effect size and significance)
    stats.reliability = abs(stats.cohens_d) * (1 - stats.p_value);
    
    % Additional metrics
    stats.spike_count_pre = sum(preRate) * binWidth;
    stats.spike_count_post = sum(postRate) * binWidth;
    stats.variance_pre = var(preRate, 'omitnan');
    stats.variance_post = var(postRate, 'omitnan');
    stats.kruskal_p = kruskalwallis([preRate(:); postRate(:)], ...
        [ones(size(preRate(:))); 2*ones(size(postRate(:)))], 'off');
end

function [responseType, responseMetrics] = classifyResponse(stats)
    % Initialize response metrics
    responseMetrics = struct();
    responseMetrics.stats = stats;
    
    % Classify response based on multiple criteria
    if stats.p_value < 0.01  % Statistically significant change
        if stats.reliability > 0.7  % High reliability
            if stats.percent_change > 20 && stats.cohens_d > 0.8
                responseType = 'Strong_Increase';
            elseif stats.percent_change < -20 && stats.cohens_d < -0.8
                responseType = 'Strong_Decrease';
            elseif stats.cohens_d > 0.5
                responseType = 'Moderate_Increase';
            elseif stats.cohens_d < -0.5
                responseType = 'Moderate_Decrease';
            else
                responseType = 'Weak_Change';
            end
        else  % Lower reliability
            if stats.mean_post > stats.mean_pre
                responseType = 'Variable_Increase';
            else
                responseType = 'Variable_Decrease';
            end
        end
    else  % Not statistically significant
        responseType = 'No_Change';
    end
    
    % Add response strength metrics
    responseMetrics.strength = struct(...
        'reliability', stats.reliability, ...
        'effect_size', stats.cohens_d, ...
        'percent_change', stats.percent_change);
end

