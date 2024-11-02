function cellDataStruct = determineResponseType(cellDataStruct, treatmentTime, binWidth, dataFolder)
    % determineResponseType: Calculates pre- and post-treatment responses for units in cellDataStruct.
    % Determines whether each unit shows an "Increased", "Decreased", or "No Change" response.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing unit data with firing rates.
    %   - treatmentTime: Time in seconds when treatment was administered.
    %   - binWidth: Width of each bin in seconds.


     % Set default value for treatmentTime if not provided
    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 1860;  % Default treatment time in seconds
        fprintf('No treatment time specified. Using default: %d seconds.\n', treatmentTime);
    end

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
                
                % If binWidth not provided as an argument, use the binWidth from the data structure
                if nargin < 3 || isempty(binWidth)
                    binWidth = unitData.binWidth;
                    fprintf('Using bin width from data structure: %.2f seconds.\n', binWidth);
                end

                % Extract the PSTH data and bin width
                psthData = unitData.psthSmoothed;  % Assumes `psthSmoothed` contains binned firing rate data
                binEdges = unitData.binEdges;
                
                % Calculate time vector for PSTH data
                timeVector = binEdges(1:end-1) + binWidth / 2;  % Bin centers
                
                % Debugging: Determine array sizes
                fprintf('Size of timeVector: [%d, %d]\n', size(timeVector));
                fprintf('Size of treatmentTime: [%d, %d]\n', size(treatmentTime));

                if ~isscalar(treatmentTime)
                    error('Expected treatmentTime to be a scalar, but it has size [%d, %d].', size(treatmentTime));
                end

                % Define pre- and post-treatment periods
                preIndices = timeVector < treatmentTime;
                postIndices = timeVector >= treatmentTime;

                % Get firing rates for pre- and post-treatment periods
                FR_before = psthData(preIndices);
                FR_after = psthData(postIndices);
                
                % Debug output to confirm extraction
                fprintf('Number of bins before treatment: %d\n', sum(preIndices));
                fprintf('Number of bins after treatment: %d\n', sum(postIndices));
                
                % Display sample data to verify
                if ~isempty(FR_before)
                    fprintf('FR_before (mean): %f\n', mean(FR_before));
                else
                    warning('FR_before is empty. Check treatment time and pre-treatment period.');
                end
                
                if ~isempty(FR_after)
                    fprintf('FR_after (mean): %f\n', mean(FR_after));
                else
                    warning('FR_after is empty. Check treatment time and post-treatment period.');
                end
                
                % Ensure we have sufficient data in both pre- and post-periods
                if isempty(FR_before) || isempty(FR_after)
                    warning('Insufficient data for Unit %s. Skipping statistical test.', unitID);
                    unitData.responseType = 'Data Missing';
                    continue;
                end

                % Perform Wilcoxon signed-rank test
                [p, ~] = ranksum(FR_before, FR_after);

                % Determine response type based on p-value and mean change
                if p < 0.05
                    if mean(FR_after) > mean(FR_before)
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
                
                % Effect size (Cohen's d)
                pooledStdDev = mean([frBaselineStdDev, frTreatmentStdDev]);
                effectSize = meanDiff / pooledStdDev;
                
                % Confidence interval (assuming normality for simplicity)
                ciLow = meanDiff - 1.96 * pooledStdDev / sqrt(length(FR_before));
                ciHigh = meanDiff + 1.96 * pooledStdDev / sqrt(length(FR_before));

                % Store p-value, response type, and additional metrics
                unitData.pValue = p;
                unitData.responseType = responseType;
                unitData.testMetaData = struct( ...
                    'MeanPre', frBaselineAvg, ...
                    'MeanPost', frTreatmentAvg, ...
                    'StdDevPre', frBaselineStdDev, ...
                    'StdDevPost', frTreatmentStdDev, ...
                    'VariancePre', frBaselineVariance, ...
                    'VariancePost', frTreatmentVariance, ...
                    'SpikeCountPre', frBaselineSpikeCount, ...
                    'SpikeCountPost', frTreatmentSpikeCount, ...
                    'EffectSize', effectSize, ...
                    'MeanDifference', meanDiff, ...
                    'ConfidenceInterval', [ciLow, ciHigh]);

                % Display debugging information
                fprintf('Unit %s | p-value: %.3f | Response: %s\n', unitID, p, responseType);

                % Save the updated unit data back to the structure
                cellDataStruct.(groupName).(recordingName).(unitID) = unitData;
            end
        end
    end

    % Save the updated struct to the specified data file path
    try
        save(dataFolder, 'cellDataStruct', '-v7');
        fprintf('Struct saved successfully to: %s\n', dataFolder);
    catch ME
        fprintf('Error saving the file: %s\n', ME.message);
    end
end

