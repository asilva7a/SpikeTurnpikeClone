function responsive_units_struct = store_unit_responses_struct(all_data, cell_types, params)
    % Initialize the responsive_units_struct
    responsive_units_struct = struct();

    % Extract parameters from the input
    binSize = params.binSize;
    moment = params.moment;
    preTreatmentPeriod = params.preTreatmentPeriod;
    postTreatmentPeriod = params.postTreatmentPeriod;

    % Iterate over all groups, recordings, and units in all_data
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        % Initialize the group field in the responsive_units_struct
        responsive_units_struct.(groupName) = struct();

        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            unitIDs = fieldnames(all_data.(groupName).(recordingName));

            % Initialize the recording field in the responsive_units_struct
            responsive_units_struct.(groupName).(recordingName) = struct();

            for u = 1:length(unitIDs)
                unitID = unitIDs{u};
                unitData = all_data.(groupName).(recordingName).(unitID);

                % Filter units by cell type and single-unit status
                if any(strcmp(cell_types, unitData.Cell_Type)) && unitData.IsSingleUnit
                    % Extract necessary data
                    spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;
                    samplingFrequency = unitData.Sampling_Frequency;
                    cellType = unitData.Cell_Type;
                    isSingleUnit = unitData.IsSingleUnit;

                    % Define bin edges
                    binEdges_Pre = max(0, moment - preTreatmentPeriod):binSize:moment;
                    binEdges_Post = moment:binSize:(moment + postTreatmentPeriod);

                    % Calculate firing rates
                    FR_before = calculate_FR(spikeTimes, binEdges_Pre);
                    FR_after = calculate_FR(spikeTimes, binEdges_Post);

                    % Handle missing data
                    FR_before = handle_missing_data(FR_before);
                    FR_after = handle_missing_data(FR_after);

                    % Perform Wilcoxon signed-rank test
                    [pValue, ~] = ranksum(FR_before, FR_after);

                    % Determine the response type
                    if pValue < 0.05
                        if mean(FR_after) > mean(FR_before)
                            responseType = 'Increased';
                        else
                            responseType = 'Decreased';
                        end
                    else
                        responseType = 'No Change';
                    end

                    % Store the data in responsive_units_struct
                    responsive_units_struct.(groupName).(recordingName).(unitID) = struct( ...
                        'SpikeTimes_all', spikeTimes, ...
                        'Sampling_Frequency', samplingFrequency, ...
                        'Cell_Type', cellType, ...
                        'IsSingleUnit', isSingleUnit, ...
                        'FR_Before', mean(FR_before), ...
                        'FR_After', mean(FR_after), ...
                        'Binned_FRs_Before', FR_before, ...
                        'Binned_FRs_After', FR_after, ...
                        'P_Value', pValue, ...
                        'ResponseType', responseType, ...
                        'Recording', recordingName, ...
                        'BinEdges_Pre', binEdges_Pre, ...
                        'BinEdges_Post', binEdges_Post ...
                    );
                end
            end
        end
    end
end

% Helper function to calculate firing rate
function FR = calculate_FR(spikeTimes, binEdges)
    % Compute histogram of spike times in specified bins
    binned_FRs = histcounts(spikeTimes, binEdges) / diff(binEdge

