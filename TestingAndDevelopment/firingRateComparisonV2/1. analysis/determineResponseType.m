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
    silence_threshold = 0.0001; % Threshold for considering a bin as silent
    silence_score_threshold = 0.95; % Threshold for silence score to classify as mostly silent

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
                
                % Initiate Unit Flags
                unitData.unitFlags = struct('isMostlySilent', false, 'isMostlyZero', false, 'isDataMissing', false);
                
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

                % Main Processing block
                if isempty(FR_before) || isempty(FR_after)
                    warning('Insufficient data for Unit %s in %s, %s. Skipping statistical tests.', unitID, groupName, recordingName);
                    unitData.unitFlags.isDataMissing = true;
                    responseType = 'Missing Data';  
                else
                    % Set flags but don't affect response type
                    isMostlySilent = (silence_score_before >= silence_score_threshold || silence_score_after >= silence_score_threshold);
                    isMostlyZero = (sum(FR_before == 0) / numel(FR_before) >= 0.6 || sum(FR_after == 0) / numel(FR_after) >= 0.6);
                    
                    % Store flags in unit data
                    unitData.unitFlags.isMostlySilent = isMostlySilent;
                    unitData.unitFlags.isMostlyZero = isMostlyZero;

                    % Perform statistical tests for all units
                    [p_wilcoxon, ~] = ranksum(FR_before, FR_after, 'alpha', 0.01);
                    combinedData = [FR_before(:); FR_after(:)];
                    groupLabels = [ones(size(FR_before(:))); 2 * ones(size(FR_after(:)))];
                    p_kruskalwallis = kruskalwallis(combinedData, groupLabels, 'off');
                    
                    % Determine response type based on statistical tests
                    if p_wilcoxon < 0.01 && p_kruskalwallis < 0.01
                        if median(FR_after) > median(FR_before)
                            responseType = 'Increased';
                        else
                            responseType = 'Decreased';
                        end
                    else
                        responseType = 'No Change';
                    end
                end
                    
                
                % Calculate additional metrics regardless of response type
                frBaselineAvg = mean(FR_before);
                frTreatmentAvg = mean(FR_after);
                frBaselineStdDev = std(FR_before);
                frTreatmentStdDev = std(FR_after);
                frBaselineVariance = var(FR_before);
                frTreatmentVariance = var(FR_after);
                frBaselineSpikeCount = sum(FR_before) * binWidth;
                frTreatmentSpikeCount = sum(FR_after) * binWidth;
                    
                % Store results, including p-values and additional metrics
                unitData.pValue = p_wilcoxon;
                unitData.responseType = responseType;  % Use the verified response type
                unitData.testMetaData = struct( ...
                    'MeanPre', frBaselineAvg, ...
                    'MeanPost', frTreatmentAvg, ...
                    'StdDevPre', frBaselineStdDev, ...
                    'StdDevPost', frTreatmentStdDev, ...
                    'VariancePre', frBaselineVariance, ...
                    'VariancePost', frTreatmentVariance, ...
                    'SpikeCountPre', frBaselineSpikeCount, ...
                    'SpikeCountPost', frTreatmentSpikeCount, ...
                    'pValue_Wilcoxon', p_wilcoxon, ...
                    'pValue_KruskalWallis', p_kruskalwallis);

               % Modified debug information to include flags
                fprintf(['Unit %s ' ...
                    '| p-value (Wilcoxon): %.3f ' ...
                    '| p-value (KW): %.3f ' ...
                    '| Response: %s ' ...
                    '| Flags: Silent=%d, Zero=%d\n'], ...
                    unitID, p_wilcoxon, p_kruskalwallis, ...
                    cliffsDelta, responseTypeVerified, ...
                    unitData.unitFlags.isMostlySilent, ...
                    unitData.unitFlags.isMostlyZero);
    
                % Save the updated unit data back to the structure
                cellDataStruct.(groupName).(recordingName).(unitID) = unitData;
      
            end
        end
    end

    % Save Updated Struct
    if nargin >= 4 && ~isempty(dataFolder)
        try
            save(fullfile(dataFolder, 'cellDataStruct.mat'), 'cellDataStruct', '-v7');
            fprintf('Struct saved successfully to: %s\n', dataFolder);
        catch ME
            % Detailed error message
            fprintf('Error saving the file:\n');
            fprintf('Message: %s\n', ME.message);
            fprintf('Identifier: %s\n', ME.identifier);
            fprintf('Stack: %s, Line %d\n', ME.stack(1).name, ME.stack(1).line);
        end
    else
        fprintf('Data folder not specified; struct not saved to disk.\n');
    end

end
