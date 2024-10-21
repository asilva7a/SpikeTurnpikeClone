function data_table_FR = FR_compare_Treatment(all_data, cell_types, binSize, plot_points, moment, period)
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
                    spikeTimes = cellData.SpikeTimes_all / cellData.Sampling_Frequency;

                    % Calculate FR for 'Before' and 'After' periods
                    FR_before = calculate_FR(spikeTimes, max(0, moment - period), moment, binSize);
                    FR_after = calculate_FR(spikeTimes, moment, min(cellData.Recording_Duration, moment + period), binSize);

                    % Store results if valid FRs are found
                    if ~isempty(FR_before)
                        FRs_vec(end+1,1) = FR_before;
                        groupsVec{end+1,1} = groupName;
                        cellTypesVec{end+1,1} = cellData.Cell_Type;
                        timePeriodVec{end+1,1} = 'Before';
                    end
                    if ~isempty(FR_after)
                        FRs_vec(end+1,1) = FR_after;
                        groupsVec{end+1,1} = groupName;
                        cellTypesVec{end+1,1} = cellData.Cell_Type;
                        timePeriodVec{end+1,1} = 'After';
                    end
                end
            end
        end
    end

    %% Plotting with gramm library
    figure;
    g = gramm('x', timePeriodVec, 'y', FRs_vec, 'color', groupsVec);
    g.facet_grid([], cellTypesVec, 'scale', 'independent');
    g.stat_summary('type', 'sem', 'geom', {'bar', 'black_errorbar'}, 'width', 0.6, 'dodge', 0.8, 'setylim', true);
    g.set_names('x', 'Time Period', 'y', 'Firing Rate (Hz)', 'Color', 'Group', 'Column', 'Cell Type');
    g.no_legend;
    g.draw();

    if plot_points
        g.update('x', timePeriodVec, 'y', FRs_vec, 'color', groupsVec);
        g.geom_point('dodge', 0.8);
        g.set_color_options('lightness', 40);
        g.set_point_options('markers', '^', 'base_size', 3);
        g.no_legend;
        g.draw;
    end

    %% Create data table for export
    data_table_FR = table(groupsVec, cellTypesVec, timePeriodVec, FRs_vec, ...
        'VariableNames', {'Group', 'CellType', 'TimePeriod', 'FR'});
end

%% Helper Function to Calculate Firing Rate
function max_FR = calculate_FR(spikeTimes, startTime, endTime, binSize)
    intervalBounds = startTime:binSize:endTime;
    binned_FRs = [];

    for ii = 1:length(intervalBounds)-1
        n_spikes = length(spikeTimes((spikeTimes >= intervalBounds(ii)) & ...
                                     (spikeTimes < intervalBounds(ii+1))));
        binned_FRs(end+1,1) = n_spikes / binSize;
    end

    if ~isempty(binned_FRs)
        max_FR = max(binned_FRs);
    else
        max_FR = [];
    end
end
