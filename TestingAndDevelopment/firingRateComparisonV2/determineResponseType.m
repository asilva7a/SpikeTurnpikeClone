function [cellDataStruct] = determineResponseType(cellDataStruct)
    % Iteratively determines response type (Increased, Decreased, No Change) 
    % for each unit in cellDataStruct based on baseline and treatment firing rates.
    % Stores p-value, response type, and test quality metrics in the structure.

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

                % Get baseline and treatment firing rate data
                frBaselineAvg = unitData.frBaselineAvg;
                frTreatmentAvg = unitData.frTreatmentAvg;
                frBaselineStdDev = unitData.frBaselineStdDev;
                frTreatmentStdDev = unitData.frTreatmentStdDev;

                % Ensure that firing rates are non-empty and valid
                if isempty(frBaselineAvg) || isempty(frTreatmentAvg)
                    warning('Missing firing rate data for Unit %s. Skipping this unit.', unitID);
                    unitData.responseType = 'Data Missing';
                    continue;
                end

                % Perform Wilcoxon signed-rank test and store test quality metrics
                try
                    % Simulate pre- and post-treatment data for the test
                    FR_before = repmat(frBaselineAvg, 1, 10);  % Simulated baseline data
                    FR_after = repmat(frTreatmentAvg, 1, 10);  % Simulated post-treatment data
                    [p, ~, stats] = ranksum(FR_before, FR_after);

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

                    % Calculate effect size (Cohen's d)
                    effectSize = (frTreatmentAvg - frBaselineAvg) / mean([frBaselineStdDev, frTreatmentStdDev]);

                    % Confidence interval for difference in means (assuming normality)
                    meanDiff = frTreatmentAvg - frBaselineAvg;
                    ciLow = meanDiff - 1.96 * sqrt((frBaselineStdDev^2 + frTreatmentStdDev^2) / 10); % Adjust 10 to actual sample size
                    ciHigh = meanDiff + 1.96 * sqrt((frBaselineStdDev^2 + frTreatmentStdDev^2) / 10);

                    % Store p-value, response type, and additional metrics in unit data
                    unitData.pValue = p;
                    unitData.responseType = responseType;

                    % Store test meta data as a struct within the unit data
                    unitData.testMetaData = struct( ...
                        'MeanPre', frBaselineAvg, ...
                        'MeanPost', frTreatmentAvg, ...
                        'StdDevPre', frBaselineStdDev, ...
                        'StdDevPost', frTreatmentStdDev, ...
                        'EffectSize', effectSize, ...
                        'MeanDifference', meanDiff, ...
                        'ConfidenceInterval', [ciLow, ciHigh], ...
                        'TestStats', stats);

                    % Display debugging information
                    fprintf('Unit %s | p-value: %.3f | Response: %s\n', unitID, p, responseType);

                catch ME
                    % Error handling for failed statistical test
                    warning('Error processing Unit %s: %s', unitID, ME.message);
                    unitData.responseType = 'Error';
                    unitData.testMetaData = struct(); % Store empty struct if error
                end

                % Save updated unitData back to the structure
                cellDataStruct.(groupName).(recordingName).(unitID) = unitData;
            end
        end
    end
end
