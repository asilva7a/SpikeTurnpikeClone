function responsive_units_struct = store_unit_responses_struct(all_data, cell_types, params)
    % Initialize the struct to store all unit data
    responsive_units_struct = struct();

    % Extract relevant parameters
    binSize = params.binSize;
    moment = params.moment;
    preTreatmentPeriod = params.preTreatmentPeriod;
    postTreatmentPeriod = params.postTreatmentPeriod;

    % Iterate over groups, recordings, and units
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            unitIDs = fieldnames(all_data.(groupName).(recordingName));

            for u = 1:length(unitIDs)
                unitID = unitIDs{u};
                unitData = all_data.(groupName).(recordingName).(unitID);

                % Check if the unit matches the specified cell types and is single-unit
                if any(strcmp(cell_types, unitData.Cell_Type)) && unitData.IsSingleUnit
                    if ~isfield(unitData, 'SpikeTimes_all') || isempty(unitData.SpikeTimes_all)
                        warning('Missing spike times for unit %s. Skipping.', unitID);
                        continue;
                    end

                    % Extract spike times and normalize by sampling frequency
                    spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                    % Define bin edges for pre- and post-treatment periods
                    preBinEdges = max(0, moment - preTreatmentPeriod):binSize:moment;
                    postBinEdges = moment:binSize:(moment + postTreatmentPeriod);

                    % Calculate firing rates before and after treatment
                    FR_before = calculate_FR(spikeTimes, preBinEdges);
                    FR_after = calculate_FR(spikeTimes, postBinEdges);

                    % Handle missing data
                    FR_before = handle_missing_data(FR_before);
                    FR_after = handle_missing_data(FR_after);

                    % Perform non-parametric test (Wilcoxon signed-rank test)
                    [p, ~] = ranksum(FR_before, FR_after);

                    % Determine response type based on p-value and firing rates
                    if p < 0.05
                        if mean(FR_after) > mean(FR_before)
                            responseType = 'Increased';
                        else
                            responseType = 'Decreased';
                        end
                    else
                        responseType = 'NoChange';
                    end

                    % Store all relevant data into the responsive_units_struct
                    responsive_units_struct.(groupName).(recordingName).(unitID) = struct(...
                        'SpikeTimes_all', unitData.SpikeTimes_all, ...
                        'Sampling_Frequency', unitData.Sampling_Frequency, ...
                        'Cell_Type', unitData.Cell_Type, ...
                        'IsSingleUnit', unitData.IsSingleUnit, ...
                        'FR_Before', mean(FR_before), ...
                        'FR_After', mean(FR_after), ...
                        'Binned_FRs_Before', FR_before, ...
                        'Binned_FRs_After', FR_after, ...
                        'P_Value', p, ...
                        'ResponseType', responseType, ...
                        'Recording', recordingName, ...
                        'BinEdges_Pre', preBinEdges, ...
                        'BinEdges_Post', postBinEdges ...
                    );
                end
            end
        end
    end
end

% Helper function to calculate firing rate with binning
function FR = calculate_FR(spikeTimes, binEdges)
    % Compute histogram of spike times within the specified bin edges
    binned_FRs = histcounts(spikeTimes, binEdges) / diff(binEdges(1:2));
    FR = binned_FRs;  % Return the raw binned firing rate
end

% Helper function to handle missing data
function FR = handle_missing_data(FR)
    if isempty(FR)
        FR = 0;
    end
end
