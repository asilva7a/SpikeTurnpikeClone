function responsive_units_struct = label_responsive_units_fun(responsive_units_struct, params)
    % Initialize parameters and smoothing window
    binSize = params.binSize;
    moment = params.moment;
    preTreatmentPeriod = params.preTreatmentPeriod;
    postTreatmentPeriod = params.postTreatmentPeriod;
    boxcarWindow = [1 1 1 1 1];  % Smoothing window

    % Iterate over groups, recordings, and units
    groupNames = fieldnames(responsive_units_struct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(responsive_units_struct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(responsive_units_struct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                % Extract spike times and normalize by sampling frequency
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                % Define bin edges for pre- and post-treatment periods
                preBinEdges = max(0, moment - preTreatmentPeriod):binSize:moment;
                postBinEdges = moment:binSize:(moment + postTreatmentPeriod);

                % Calculate firing rates with smoothing
                FR_before = calculate_FR(spikeTimes, preBinEdges, boxcarWindow);
                FR_after = calculate_FR(spikeTimes, postBinEdges, boxcarWindow);

                % Handle missing data
                FR_before = handle_missing_data(FR_before);
                FR_after = handle_missing_data(FR_after);

                % Perform Wilcoxon signed-rank test
                [p, ~] = ranksum(FR_before, FR_after);

                % Determine the response type
                if p < 0.05
                    if mean(FR_after) > mean(FR_before)
                        responseType = 'Increased';
                    else
                        responseType = 'Decreased';
                    end
                else
                    responseType = 'No Change';
                end

                % Store results in the responsive_units_struct
                responsive_units_struct.(groupName).(recordingName).(unitID).FR_Before = mean(FR_before);
                responsive_units_struct.(groupName).(recordingName).(unitID).FR_After = mean(FR_after);
                responsive_units_struct.(groupName).(recordingName).(unitID).Binned_FRs_Before = FR_before;
                responsive_units_struct.(groupName).(recordingName).(unitID).Binned_FRs_After = FR_after;
                responsive_units_struct.(groupName).(recordingName).(unitID).P_Value = p;
                responsive_units_struct.(groupName).(recordingName).(unitID).ResponseType = responseType;
            end
        end
    end

    fprintf('Labeling completed.\n');
end

% Helper function to calculate firing rate with smoothing
function smoothed_FR = calculate_FR(spikeTimes, binEdges, smoothingWindow)
    % Compute histogram of spike times in specified bins
    binned_FRs = histcounts(spikeTimes, binEdges) / diff(binEdges(1:2));

    % Apply boxcar smoothing
    smoothed_FR = conv(binned_FRs, smoothingWindow, 'same');
end

% Helper function to handle missing data
function FR = handle_missing_data(FR)
    if isempty(FR)
        FR = 0;
    end
end
