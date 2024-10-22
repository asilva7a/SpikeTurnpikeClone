function data_table_FR = FR_compare_Treatment(all_data, cell_types, binSize, plot_points, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Input: 
    % - preTreatmentPeriod: Duration (in seconds) to analyze before the moment
    % - postTreatmentPeriod: Duration (in seconds) to analyze after the moment

    groupNames = fieldnames(all_data);

    % Initialize vectors to store results
    groupsVec = {};
    cellTypesVec = {};
    FRs_vec = [];
    timePeriodVec = {}; % Store time period information ('Before', 'After')

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

                    % Calculate FR for the period *before* treatment
                    FR_before = calculate_FR(spikeTimes, max(0, moment - preTreatmentPeriod), moment, binSize);
                    % Calculate FR for the period *after* treatment
                    FR_after = calculate_FR(spikeTimes, moment, min(cellData.Recording_Duration, moment + postTreatmentPeriod), binSize);

                    % Assign 0 Hz if no spikes were found in the period
                    if isempty(FR_before), FR_before = 0; end
                    if isempty(FR_after), FR_after = 0; end

                    % Store results for 'Before' period
                    FRs_vec(end+1,1) = FR_before;
                    groupsVec{end+1,1} = groupName;
                    cellTypesVec{end+1,1} = cellData.Cell_Type;
                    timePeriodVec{end+1,1} = 'Before';

                    % Store results for 'After' period
                    FRs_vec(end+1,1) = FR_after;
                    groupsVec{end+1,1} = groupName;
                    cellTypesVec{end+1,1} = cellData.Cell_Type;
                    timePeriodVec{end+1,1} = 'After';
                end
            end
        end
    end

  %% Plotting with gramm library
    figure;
    
    % Ensure 'Before' and 'After' are treated as consistent categorical levels
    timePeriodVec = categorical(timePeriodVec, {'Before', 'After'});
    
    % Create a gramm object, grouping only by cell type (ignoring recording group)
    g = gramm('x', timePeriodVec, 'y', FRs_vec, 'color', cellTypesVec);
    
    % Facet by cell type (only columns), without grouping by recording group
    g.facet_grid([], [], 'scale', 'independent');
    
    % Plot bars with SEM error bars
    g.stat_summary('type', 'sem', 'geom', {'bar', 'black_errorbar'}, ...
                   'width', 0.6, 'dodge', 0.8, 'setylim', true);
    
    % Set axis labels and title
    g.set_names('x', 'Time Period', 'y', 'Firing Rate (Hz)', 'Color', 'Cell Type');
    
    % Hide legend (optional)
    g.no_legend;
    
    % Draw the plot
    g.draw();
    
    %% Optional: Add individual points to the plot
    if plot_points
        % Update the plot to add points on top of the bars
        g.update('x', timePeriodVec, 'y', FRs_vec, 'color', cellTypesVec);
    
        % Plot individual points with slight dodge for clarity
        g.geom_point('dodge', 0.8);
    
        % Set marker and point options
        g.set_color_options('lightness', 40);  % Adjust point lightness
        g.set_point_options('markers', {'^'}, 'base_size', 3);  % Ensure valid marker
    
        % Hide legend again, as individual points don’t need separate labels
        g.no_legend;
    
        % Draw the updated plot with points
        g.draw();
    end

    %% Create data table for export
        data_table_FR = table(groupsVec, cellTypesVec, timePeriodVec, FRs_vec, ...
            'VariableNames', {'Group', 'CellType', 'TimePeriod', 'FR'});
    % Export Data to CSV
    csvFileName = 'processed_FR_data.csv';  % Specify your desired filename
    writetable(data_table_FR, csvFileName);

    % Display confirmation
    fprintf('Data successfully exported to %s\n', csvFileName);
    
    end

%% Helper Function to Calculate Average Firing Rate (FR)
function avg_FR = calculate_FR(spikeTimes, startTime, endTime, binSize)
    % Generate precise interval bounds without rounding
    intervalBounds = startTime:binSize:endTime;
    binned_FRs = [];  % Store firing rates for each bin

    % Loop through bins and compute firing rate for each
    for ii = 1:length(intervalBounds) - 1
        % Count spikes within the exact interval
        n_spikes = length(spikeTimes( ...
            spikeTimes >= intervalBounds(ii) & spikeTimes < intervalBounds(ii + 1)));
        
        % Calculate firing rate in Hz (spikes per second)
        FR_in_bin = n_spikes / binSize;

        % Store the firing rate
        binned_FRs(end + 1, 1) = FR_in_bin;
    end

    % Return the average firing rate across bins, or 0 if no bins exist
    if ~isempty(binned_FRs)
        avg_FR = mean(binned_FRs);  % Compute the average
    else
        avg_FR = 0;  % No spikes or bins, set FR to 0
    end
end