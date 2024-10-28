function responsive_units_struct = store_unit_responses_struct(all_data, cell_types, params)
    % Extract analysis parameters from the input struct `params`
    binSize = params.binSize;
    moment = params.moment;
    preTreatmentPeriod = params.preTreatmentPeriod;
    postTreatmentPeriod = params.postTreatmentPeriod;
    boxcarWindow = params.smoothingWindow;  % Boxcar smoothing window

    % Initialize the nested struct for all units
    responsive_units_struct = struct();

    % Iterate over all groups, recordings, and units
    groupNames = fieldnames(all_data);
    for groupNum = 1:length(groupNames)
        groupName = groupNames{groupNum};
        recordingNames = fieldnames(all_data.(groupName));

        for recordingNum = 1:length(recordingNames)
            recordingName = recordingNames{recordingNum};
            cellIDs = fieldnames(all_data.(groupName).(recordingName));

            for cellID_num = 1:length(cellIDs)
                cellID = cellIDs{cellID_num};
                cellData = all_data.(groupName).(recordingName).(cellID);

                % Default values for non-responsive units
                responseType = 'No Change';
                FR_before = NaN;
                FR_after = NaN;
                p = NaN;

                % Process unit if it's a Single Unit with spike data
                if any(strcmp(cell_types, cellData.Cell_Type)) && cellData.IsSingleUnit && ...
                   isfield(cellData, 'SpikeTimes_all') && ~isempty(cellData.SpikeTimes_all)

                    % Extract spike times and normalize by sampling frequency
                    spikeTimes = cellData.SpikeTimes_all / cellData.Sampling_Frequency;

                    % Define bin edges for pre- and post-treatment periods
                    preBinEdges = max(0, moment - preTreatmentPeriod):binSize:moment;
                    postBinEdges = moment:binSize:(moment + postTreatmentPeriod);

                    % Calculate firing rates before and after treatment
                    FR_before = calculate_FR(spikeTimes, preBinEdges, boxcarWindow);
                    FR_after = calculate_FR(spikeTimes, postBinEdges, boxcarWindow);

                    % Perform non-parametric test (Wilcoxon signed-rank test)
                    [p, ~] = ranksum(FR_before, FR_after);

                    % Determine response type based on p-value and rate changes
                    if p < 0.05
                        if mean(FR_after) > mean(FR_before)
                            responseType = 'Increased';
                        else
                            responseType = 'Decreased';
                        end
                    end
                end

                % Store unit data in the nested struct
                responsive_units_struct.(groupName).(recordingName).(cellID) = struct( ...
                    'FR_Before', mean(FR_before), ...
                    'FR_After', mean(FR_after), ...
                    'Binned_FRs_Before', FR_before, ...
                    'Binned_FRs_After', FR_after, ...
                    'P_Value', p, ...
                    'ResponseType', responseType, ...
                    'CellType', cellData.Cell_Type ...
                );
            end
        end
    end
end

% Helper function to calculate firing rate with smoothing
function smoothed_FR = calculate_FR(spikeTimes, binEdges, smoothingWindow)
    % Compute histogram of spike times in specified bins
    binned_FRs = histcounts(spikeTimes, binEdges) / diff(binEdges(1:2));

    % Apply boxcar smoothing using convolution
    smoothed_FR = conv(binned_FRs, smoothingWindow, 'same');
end
