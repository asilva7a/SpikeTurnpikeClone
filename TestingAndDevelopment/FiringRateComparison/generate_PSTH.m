function generate_PSTH(all_data, binSize, smoothingWindow, moment, prePeriod, postPeriod)
    % Generate and plot time-locked PSTHs for each unit.

    groupNames = fieldnames(all_data);

    % Iterate over groups, mice, and units
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        mouseNames = fieldnames(all_data.(groupName));

        for m = 1:length(mouseNames)
            mouseName = mouseNames{m};
            cellIDs = fieldnames(all_data.(groupName).(mouseName));

            for c = 1:length(cellIDs)
                cellID = cellIDs{c};
                cellData = all_data.(groupName).(mouseName).(cellID);

                % Get spike times in seconds
                spikeTimes = cellData.SpikeTimes_all / cellData.Sampling_Frequency;

                % Generate PSTH for the entire recording
                edges = 0:binSize:(cellData.Recording_Duration);  % Define bin edges
                counts = histcounts(spikeTimes, edges);  % Get spike counts

                % Apply light smoothing
                smoothedCounts = conv(counts, smoothingWindow, 'same') / binSize;

                % Plot individual PSTH
                plot_unit_PSTH(smoothedCounts, cellID, cellData);
            end
        end
    end
end
