function data_table_FR = FR_compare_Treatment(all_data, cell_types, binSize, plot_points, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Input: 
    % - preTreatmentPeriod: Duration (in seconds) to analyze before the moment
    % - postTreatmentPeriod: Duration (in seconds) to analyze after the moment

    groupNames = fieldnames(all_data);

    % Initialize vectors to store results
    groupsVec = {};
    cellTypesVec = {};
    FRs_before = [];  % Store firing rates before treatment
    FRs_after = [];   % Store firing rates after treatment
    unitIDs = {};     % Store unit IDs (for tracking and exporting)
    responseTypeVec = {}; % Store the response type (Increased, Decreased, No Change)

    % Iterate over groups, mice, and cells
    for groupNum = 1:length(groupNames)
        groupName = groupNames{groupNum};
        mouseNames = fieldnames(all_data.(groupName));

        for mouseNum = 1:length(mouseNames)
            mouseName = mouseNames{mouseNum};
            cellIDs = fieldnames(all_data.(groupName).(mouseName));

            for cellID_num = 1:length(cellIDs)
                cellID = cellIDs{cellID_num};
                cellData = all_data.(groupName).(mouseName).(cellID);

                % Check if the cell matches the required type and is a single unit
                if any(strcmp(cell_types, cellData.Cell_Type)) && cellData.IsSingleUnit
                    if ~isfield(cellData, 'SpikeTimes_all') || isempty(cellData.SpikeTimes_all)
                        warning('Missing spike times for cell %s. Skipping.', cellID);
                        continue;
                    end

                    % Convert spike times from samples to seconds
                    spikeTimes = cellData.SpikeTimes_all / cellData.Sampling_Frequency;

                    % Calculate FR for the period before treatment
                    FR_before = calculate_FR(spikeTimes, max(0, moment - preTreatmentPeriod), moment, binSize);
                    % Calculate FR for the period after treatment
                    FR_after = calculate_FR(spikeTimes, moment, min(cellData.Recording_Duration, moment + postTreatmentPeriod), binSize);

                    % Handle missing firing rates
                    if isempty(FR_before), FR_before = 0; end
                    if isempty(FR_after), FR_after = 0; end

                    % Store results
                    FRs_before(end+1,1) = FR_before;
                    FRs_after(end+1,1) = FR_after;
                    groupsVec{end+1,1} = groupName;
                    cellTypesVec{end+1,1} = cellData.Cell_Type;
                    unitIDs{end+1,1} = cellID;
                end
            end
        end
    end

    %% Perform Paired t-Test for Each Unit
    p_vals = nan(length(FRs_before), 1);  % Pre-allocate p-values array
    h_vals = nan(length(FRs_before), 1);  % Pre-allocate hypothesis test results

    for i = 1:length(FRs_before)
        % Perform paired t-test for each unit
        [h, p] = ttest(FRs_before(i), FRs_after(i));
        
        % Store the results
        h_vals(i) = h;  % Hypothesis test result (1 = significant, 0 = not significant)
        p_vals(i) = p;  % P-value for the test
    end

    % Classify units based on p-values and firing rate differences
    for i = 1:length(FRs_before)
        if p_vals(i) < 0.05  % Significant change
            if FRs_after(i) > FRs_before(i)
                responseTypeVec{i,1} = 'Increased';
            else
                responseTypeVec{i,1} = 'Decreased';
            end
        else
            responseTypeVec{i,1} = 'No Change';
        end
    end


    %% Create Data Table for Export
    data_table_FR = table(unitIDs, groupsVec, cellTypesVec, FRs_before, FRs_after, responseTypeVec, ...
        'VariableNames', {'UnitID', 'Group', 'CellType', 'FR_Before', 'FR_After', 'ResponseType'});

    % Export data to CSV
    csvFileName = 'processed_FR_data_with_stats.csv';
    writetable(data_table_FR, csvFileName);

    fprintf('Data with statistical results successfully exported to %s\n', csvFileName);

    %% Visualize Results by Response Type
    figure;
    g = gramm('x', responseTypeVec, 'y', FRs_after - FRs_before, 'color', cellTypesVec);

    % Facet by cell type to separate RS and FS units
    g.facet_grid([], cellTypesVec, 'scale', 'independent');

    % Plot bars showing the mean change in firing rate with SEM error bars
    g.stat_summary('type', 'sem', 'geom', {'bar', 'black_errorbar'}, ...
                   'width', 0.6, 'dodge', 0.8);

    % Set axis labels and title
    g.set_names('x', 'Response Type', 'y', 'Change in Firing Rate (Hz)', 'Color', 'Cell Type');
    g.set_title('Change in Firing Rate (Post - Pre) by Response Type');

    % Draw the plot
    g.draw();
end

%% Helper Function to Calculate Firing Rate (Average FR)
function avg_FR = calculate_FR(spikeTimes, startTime, endTime, binSize)
    % Generate precise interval bounds
    intervalBounds = startTime:binSize:endTime;
    binned_FRs = [];  % Store firing rates for each bin

    % Loop through bins and compute firing rate
    for ii = 1:length(intervalBounds) - 1
        n_spikes = length(spikeTimes( ...
            spikeTimes >= intervalBounds(ii) & spikeTimes < intervalBounds(ii + 1)));
        FR_in_bin = n_spikes / binSize;  % FR in Hz
        binned_FRs(end + 1, 1) = FR_in_bin;
    end

    % Return the average firing rate
    if ~isempty(binned_FRs)
        avg_FR = mean(binned_FRs);
    else
        avg_FR = 0;
    end
end
