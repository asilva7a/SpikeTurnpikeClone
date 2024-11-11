function cellDataStruct = determineResponseType(cellDataStruct, treatmentTime, binWidth, dataFolder)
    % determineResponseType: Calculates pre- and post-treatment responses for units in cellDataStruct.
    % Determines whether each unit shows an "Increased", "Decreased", or "No Change" response.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing unit data with firing rates.
    %   - treatmentTime: Time in seconds when treatment was administered.
    %   - binWidth: Width of each bin in seconds.
    %   - dataFolder: Path to save the updated cellDataStruct file.

    % Set default treatment time if not provided
    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 1860;
        fprintf('No treatment time specified. Using default: %d seconds.\n', treatmentTime);
    end

    % Define silence score parameters
    silence_threshold = 0.01; % Threshold for considering a bin as silent
    silence_score_threshold = 0.6; % Threshold for silence score to classify as mostly silent

    % Loop over all groups, recordings, and units
    groupNames = fieldnames(cellDataStruct);

    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Use the binWidth from the data structure if not provided
                if nargin < 3 || isempty(binWidth)
                    binWidth = unitData.binWidth;
                    fprintf('Using bin width from data structure: %.2f seconds.\n', binWidth);
                end

                % Extract PSTH data and bin edges
                psthData = unitData.psthSmoothed;
                binEdges = unitData.binEdges;

                % Calculate time vector for PSTH data
                timeVector = binEdges(1:end-1) + binWidth / 2;

                % Define pre- and post-treatment periods
                preIndices = timeVector < treatmentTime;
                postIndices = timeVector >= treatmentTime;

                % Get firing rates for pre- and post-treatment periods
                FR_before = psthData(preIndices);
                FR_after = psthData(postIndices);

                % Calculate silence scores
                [silence_score_before, silence_score_after] = calculateSilenceScore(FR_before, FR_after, binWidth, silence_threshold);
                
                % Store Silence Score in Unit Data
                unitData.silenceScoreBefore = silence_score_before; % Add silence score outside of metadata struct
                unitData.silenceScoreAfter = silence_score_after;

                % Check for mostly silent data
                if isempty(FR_before) || isempty(FR_after)
                    warning('Insufficient data for Unit %s in %s, %s. Skipping statistical tests.', unitID, groupName, recordingName);
                    unitData.responseType = 'Data Missing';
                elseif silence_score_before >= silence_score_threshold || silence_score_after >= silence_score_threshold
                    warning('Mostly silent data for Unit %s in %s, %s. Skipping statistical tests.', unitID, groupName, recordingName);
                    unitData.responseType = 'Mostly Silent';
                elseif sum(FR_before == 0) / numel(FR_before) >= 0.6 || sum(FR_after == 0) / numel(FR_after) >= 0.6
                    warning('Mostly zero data for Unit %s in %s, %s. Skipping statistical tests.', unitID, groupName, recordingName);
                    unitData.responseType = 'Mostly Zero';
                else
                    % Perform Wilcoxon signed-rank test
                    [p_wilcoxon, ~] = ranksum(FR_before, FR_after);
    
                    % Perform Kruskal-Wallis test for distribution differences between pre- and post-treatment
                    combinedData = [FR_before(:); FR_after(:)];
                    groupLabels = [ones(size(FR_before(:))); 2 * ones(size(FR_after(:)))];
                    p_kruskalwallis = kruskalwallis(combinedData, groupLabels, 'off');
    
                    % Determine response type based on both p-values and median change
                    if p_wilcoxon < 0.01 && p_kruskalwallis < 0.01
                        if median(FR_after) > median(FR_before)
                            responseType = 'Increased';
                        else
                            responseType = 'Decreased';
                        end
                    else
                        responseType = 'No Change';
                    end
    
                    % Calculate additional quality metrics
                    frBaselineAvg = mean(FR_before);
                    frTreatmentAvg = mean(FR_after);
                    frBaselineStdDev = std(FR_before);
                    frTreatmentStdDev = std(FR_after);
                    frBaselineVariance = var(FR_before);
                    frTreatmentVariance = var(FR_after);
                    frBaselineSpikeCount = sum(FR_before) * binWidth;
                    frTreatmentSpikeCount = sum(FR_after) * binWidth;
                    meanDiff = frTreatmentAvg - frBaselineAvg;
    
                    % Calculate Cliff's Delta
                    cliffsDelta = calculateCliffsDelta(FR_before, FR_after);
    
                    % Verify if Cliff's Delta matches the response label
                    responseTypeVerified = checkCliffsDelta(responseType, cliffsDelta);
    
                    % Store results, including p-values and additional metrics
                    unitData.pValue = p_wilcoxon;
                    unitData.responseType = responseTypeVerified;  % Use the verified response type
                    unitData.testMetaData = struct( ...
                        'MeanPre', frBaselineAvg, ...
                        'MeanPost', frTreatmentAvg, ...
                        'StdDevPre', frBaselineStdDev, ...
                        'StdDevPost', frTreatmentStdDev, ...
                        'VariancePre', frBaselineVariance, ...
                        'VariancePost', frTreatmentVariance, ...
                        'SpikeCountPre', frBaselineSpikeCount, ...
                        'SpikeCountPost', frTreatmentSpikeCount, ...
                        'CliffsDelta', cliffsDelta, ...
                        'MeanDifference', meanDiff, ...
                        'pValue_Wilcoxon', p_wilcoxon, ...
                        'pValue_KruskalWallis', p_kruskalwallis);
    
                    % Display debug information
                    fprintf('Unit %s | p-value (Wilcoxon): %.3f | p-value (Kruskal-Wallis): %.3f | Cliff''s Delta: %.3f | Response: %s\n', ...
                        unitID, p_wilcoxon, p_kruskalwallis, cliffsDelta, responseTypeVerified);
                end

                % Save the updated unit data back to the structure
                cellDataStruct.(groupName).(recordingName).(unitID) = unitData;

            end
        end
    end

    % Save the updated struct to the specified data file path
    if nargin >= 4 && ~isempty(dataFolder)
        try
            save(fullfile(dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7');
            fprintf('Struct saved successfully to: %s\n', dataFolder);
        catch ME
            fprintf('Error saving the file: %s\n', ME.message);
        end
    else
        fprintf('Data folder not specified; struct not saved to disk.\n');
    end
end

%% Helper Function to Calculate Cliff's Delta
function cliffsDelta = calculateCliffsDelta(FR_before, FR_after)
    n1 = length(FR_before);
    n2 = length(FR_after);
    delta = 0;
    for i = 1:n1
        for j = 1:n2
            delta = delta + sign(FR_after(j) - FR_before(i));
        end
    end
    cliffsDelta = delta / (n1 * n2);
end

%% Helper Function to Check Cliff's Delta against Response Type
function responseTypeVerified = checkCliffsDelta(responseType, cliffsDelta)
    % Set thresholds for Cliff's Delta interpretation
    threshold = 0.147; % Common threshold to indicate a small effect size for Cliff's Delta
    % Determine if Cliff's Delta agrees with the response type label
    switch responseType
        case 'Increased'
            if cliffsDelta < threshold
                fprintf('Warning: Cliff''s Delta (%.3f) does not support "Increased" response type.\n', cliffsDelta);
                responseTypeVerified = 'No Change';
            else
                responseTypeVerified = 'Increased';
            end
        case 'Decreased'
            if cliffsDelta > -threshold
                fprintf('Warning: Cliff''s Delta (%.3f) does not support "Decreased" response type.\n', cliffsDelta);
                responseTypeVerified = 'No Change';
            else
                responseTypeVerified = 'Decreased';
            end
        otherwise
            responseTypeVerified = 'No Change';
    end
end
