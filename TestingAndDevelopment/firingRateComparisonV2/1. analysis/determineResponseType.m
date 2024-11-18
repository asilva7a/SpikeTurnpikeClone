function cellDataStruct = determineResponseType(cellDataStruct, paths, params, varargin)
% determineResponseType - Determines the response type for each unit in the cellDataStruct
%
% Inputs:
%   cellDataStruct - Structure containing cell data
%   paths - Structure containing file paths
%   params - Structure containing analysis parameters
%   varargin - Optional name-value pair arguments
%
% Outputs:
%   cellDataStruct - Updated structure with response types added
%
% Nested Functions:
%   1. processUnit(unitData, preWindow, postWindow, silenceThreshold, silenceScoreThreshold, binWidth, params, opts)
%      Inputs: Unit data and various parameters
%      Outputs: Processed unit data with response type and metrics
%
%   2. calculateResponseStats(preRate, postRate, binWidth)
%      Inputs: Pre and post firing rates, bin width
%      Outputs: Structure containing various statistical measures
%
%   3. classifyResponse(stats)
%      Inputs: Statistics structure from calculateResponseStats
%      Outputs: Response type and response metrics

%% Parse Input

    % Parse input parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct', @isstruct);
    addRequired(p, 'paths', @isstruct);
    addRequired(p, 'params', @isstruct);
    
    % Optional parameters with defaults
    addParameter(p, 'tagSparse', false, @islogical);
    addParameter(p, 'silenceThreshold', 0.0001, @isnumeric);
    addParameter(p, 'silenceScoreThreshold', 0.95, @isnumeric);
    
    % Parse inputs
    parse(p, cellDataStruct, paths, params, varargin{:});
    opts = p.Results;

    %% Main Processing Loop
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

                    unitResults{u} = processUnit(unitData{u}, params.preWindow, params.postWindow, ...
                          opts.silenceThreshold, opts.silenceScoreThreshold, ...
                          params.binWidth, params.treatmentTime);
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
                    
                    processedUnit = processUnit(unitData, params.preWindow, params.postWindow, ...
                         opts.silenceThreshold, opts.silenceScoreThreshold, ...
                         params.binWidth, params.treatmentTime);

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


function unitData  = processUnit(unitData, preWindow, postWindow, ...
    silenceThreshold, silenceScoreThreshold, binWidth, treatmentTime)

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
    
    % Determine response type 
    [responseType, responseMetrics] = classifyResponse(stats, ...
        unitData.psthSmoothed, treatmentTime, binWidth);
    
    % Store results
    unitData.pValue = stats.p_value;
    unitData.responseType = responseType;
    unitData.responseMetrics = responseMetrics;
    unitData.stats = stats;
end