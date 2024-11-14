function cellDataStruct = determineResponseType(cellDataStruct, treatmentTime, binWidth, dataFolder, tagSparse)
    % Set default parameters
    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 1860;
        fprintf('No treatment time specified. Using default: %d seconds.\n', treatmentTime);
    end
    if nargin < 5
        tagSparse = false;
    end
    
    % Constants
    SILENCE_THRESHOLD = 0.0001;
    SILENCE_SCORE_THRESHOLD = 0.95;
    PRE_WINDOW = [0, 1800];
    POST_WINDOW = [2000, 3800];
    
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
                % Pre-allocate cell array to store results
                unitResults = cell(numUnits, 1);
                unitData = cell(numUnits, 1);
                
                % Extract unit data for parallel processing
                for u = 1:numUnits
                    unitData{u} = cellDataStruct.(groupName).(recordingName).(units{u});
                end
                
                % Process units in parallel
                parfor u = 1:numUnits
                    unitResults{u} = processUnit(unitData{u}, PRE_WINDOW, POST_WINDOW, ...
                                              SILENCE_THRESHOLD, SILENCE_SCORE_THRESHOLD, ...
                                              binWidth);
                end
                
                % Update cellDataStruct with results
                for u = 1:numUnits
                    if ~isempty(unitResults{u})
                        cellDataStruct.(groupName).(recordingName).(units{u}) = unitResults{u};
                    end
                end
            else
                % Process units serially for small datasets
                for u = 1:numUnits
                    unitID = units{u};
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    % Process unit and store results
                    processedUnit = processUnit(unitData, PRE_WINDOW, POST_WINDOW, ...
                                             SILENCE_THRESHOLD, SILENCE_SCORE_THRESHOLD, ...
                                             binWidth);
                    if ~isempty(processedUnit)
                        cellDataStruct.(groupName).(recordingName).(unitID) = processedUnit;
                    end
                end
            end
        end
    end
    
    % Optional: Run sparse unit detection
    if tagSparse
        try
            [cellDataStruct, ~] = tagSparseUnits(cellDataStruct, binWidth, 0.5, dataFolder);
        catch ME
            fprintf('Error in sparse unit detection: %s\n', ME.message);
        end
    end
    
    % Save results
    if nargin >= 4 && ~isempty(dataFolder)
        try
            save(fullfile(dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7.3', '-nocompression');
            fprintf('Data saved successfully to: %s\n', dataFolder);
        catch ME
            fprintf('Error saving data: %s\n', ME.message);
        end
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
    
    % Calculate silence scores
    silenceScoreBefore = mean(frBefore < silenceThreshold);
    silenceScoreAfter = mean(frAfter < silenceThreshold);
    unitData.unitFlags.isMostlySilent = (silenceScoreBefore >= silenceScoreThreshold || ...
                                        silenceScoreAfter >= silenceScoreThreshold);
    
    % Statistical tests
    [pWilcoxon, ~] = signrank(frBefore, frAfter, 'alpha', 0.01);
    combinedData = [frBefore(:); frAfter(:)];
    groupLabels = [ones(size(frBefore(:))); 2*ones(size(frAfter(:)))];
    pKruskalWallis = kruskalwallis(combinedData, groupLabels, 'off');
    
    % Determine response type
    if pWilcoxon < 0.01
        if median(frAfter) > median(frBefore)
            responseType = 'Increased';
        else
            responseType = 'Decreased';
        end
    else
        responseType = 'No Change';
    end
    
    % Store results
    unitData.pValue = pWilcoxon;
    unitData.responseType = responseType;
    unitData.testMetaData = struct(...
        'MeanPre', mean(frBefore), ...
        'MeanPost', mean(frAfter), ...
        'StdDevPre', std(frBefore), ...
        'StdDevPost', std(frAfter), ...
        'VariancePre', var(frBefore), ...
        'VariancePost', var(frAfter), ...
        'SpikeCountPre', sum(frBefore) * binWidth, ...
        'SpikeCountPost', sum(frAfter) * binWidth, ...
        'pValue_Wilcoxon', pWilcoxon, ...
        'pValue_KruskalWallis', pKruskalWallis);
end

