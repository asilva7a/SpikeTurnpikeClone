function responsive_units_struct = store_unit_responses_struct(all_data, cell_types, params, saveDir)
    % Initialize the responsive_units_struct
    responsive_units_struct = struct();

    % Extract parameters from input
    binSize = params.binSize;
    moment = params.moment;
    preTreatmentPeriod = params.preTreatmentPeriod;
    postTreatmentPeriod = params.postTreatmentPeriod;
    pValueThreshold = params.pValueThreshold;

    % Iterate over all groups, recordings, and units
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

                % Check if the unit belongs to the specified cell types
                if any(strcmp(cell_types, unitData.Cell_Type))
                    % Extract and convert spike times to seconds
                    spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;
                    samplingFrequency = unitData.Sampling_Frequency;
                    cellType = unitData.Cell_Type;
                    isSingleUnit = unitData.IsSingleUnit;

                    % Define bin edges for pre- and post-treatment periods
                    binEdges_Pre = max(0, moment - preTreatmentPeriod):binSize:moment;
                    binEdges_Post = moment:binSize:(moment + postTreatmentPeriod);

                    % Calculate firing rates
                    [FR_before, FR_after] = calculate_FR(spikeTimes, binEdges_Pre, binEdges_Post);

                    % Perform statistical test and classify the response
                    [pValue, ~] = ranksum(FR_before, FR_after);
                    responseType = classify_response(pValue, mean(FR_before), mean(FR_after), pValueThreshold);

                    % Store all relevant data in the responsive_units_struct
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

    % Save the responsive_units_struct to the specified directory
    save_path = fullfile(saveDir, 'responsive_units_struct.mat');
    save(save_path, 'responsive_units_struct');
    disp(['Saved responsive_units_struct to: ', save_path]);
end


%% Helper Functions

function [FR_before, FR_after] = calculate_FR(spikeTimes, binEdges_Pre, binEdges_Post)
    % Compute histograms for pre and post periods
    FR_before = histcounts(spikeTimes, binEdges_Pre) / diff(binEdges_Pre(1:2));
    FR_after = histcounts(spikeTimes, binEdges_Post) / diff(binEdges_Post(1:2));

    % Debugging output for firing rates
    disp(['FR Before: ', num2str(FR_before)]);
    disp(['FR After: ', num2str(FR_after)]);

    % Handle cases where firing rates might be empty
    FR_before = handle_missing_data(FR_before);
    FR_after = handle_missing_data(FR_after);
end

function FR = handle_missing_data(FR)
    if isempty(FR)
        FR = NaN;  % Use NaN to distinguish from real zero firing rates
    end
end

% Classify the response type based on p-value and firing rates
function responseType = classify_response(pValue, FR_before, FR_after, pValueThreshold)
    if pValue < pValueThreshold
        if FR_after > FR_before
            responseType = 'Increased';
        else
            responseType = 'Decreased';
        end
    else
        responseType = 'No Change';
    end
end
