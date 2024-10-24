function generate_PSTHs_by_response(all_data, binSize, smoothingWindow, moment, prePeriod, postPeriod)
    % Generate three plots:
    % 1. Overlay PSTHs for responsive units (Increased or Decreased).
    % 2. Overlay PSTHs for non-responsive units.
    % 3. Mean ± SEM PSTHs for all units.
    % Reuses existing functions from the analysis pipeline.

    % Initialize containers for PSTHs
    allPSTHs = [];  % Store all PSTHs for mean ± SEM calculation
    responsivePSTHs = [];  % Store PSTHs for responsive units
    nonResponsivePSTHs = [];  % Store PSTHs for non-responsive units

    % Iterate through all groups and recordings
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            unitNames = fieldnames(all_data.(groupName).(recordingName));

            % Process each unit within the current recording
            for u = 1:length(unitNames)
                unitName = unitNames{u};
                unitData = all_data.(groupName).(recordingName).(unitName);

                % Use existing spike alignment and PSTH logic
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                %Generate PSTH for the unit
                edges = 0:binSize(cellData.Recording_Duration); %define bin edges
                counts = histcounts(spikeTimes, edges); %count spikes in each bin

                % Smooth the PSTH using the provided smoothing window
                smoothedPSTH = conv(psthCounts, smoothingWindow, 'same') / binSize;

                % Store the PSTH for later aggregation
                allPSTHs = [allPSTHs; smoothedPSTH];

                % Classify based on ResponseType and store accordingly
                if ismember(unitData.ResponseType, {'Increased', 'Decreased'})
                    responsivePSTHs = [responsivePSTHs; smoothedPSTH];
                else
                    nonResponsivePSTHs = [nonResponsivePSTHs; smoothedPSTH];
                end
            end
        end
    end
