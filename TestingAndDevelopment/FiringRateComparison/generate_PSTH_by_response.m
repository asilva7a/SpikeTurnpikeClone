function generate_PSTHs_by_response(all_data, binSize, smoothingWindow, moment, prePeriod, postPeriod)
    % Generate three plots:
    % 1. Overlay PSTHs for responsive units (Increased or Decreased).
    % 2. Overlay PSTHs for non-responsive units.
    % 3. Mean+/-SEM PSTHs for all units 

    % Initialize containers for PSTHs
    allPSTHs = []; %store all PSTHs for mean+/-SEM calculation
    responsivePSTHs = []; %store PSTHs for responsive units
    nonResponsivePSTHs = []; %store PSTHs for non-responsive units

    %% Iterate through all groups, mice, and units

    groupNames = fieldnames(all_data);

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
