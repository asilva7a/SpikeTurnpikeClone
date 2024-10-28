function psthData = generate_unit_PSTHs(responsive_units_struct, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Initialize storage structure for PSTHs
    psthData = struct();

    % Get group names
    groupNames = fieldnames(responsive_units_struct);

    % Iterate over all groups
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(responsive_units_struct.(groupName));  % Get recording names

        % Initialize the group in psthData
        psthData.(groupName) = struct();

        % Iterate over recordings within the group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(responsive_units_struct.(groupName).(recordingName));  % Get unit IDs

            % Iterate over each unit
            for u = 1:length(units)
                unitID = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                % Check if spike times exist
                if ~isfield(unitData, 'SpikeTimes_all') || isempty(unitData.SpikeTimes_all)
                    warning('Missing data for unit %s. Skipping.', unitID);
                    continue;
                end

                % Extract spike times and normalize by sampling frequency
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                % Define bin edges
                binEdges = moment - preTreatmentPeriod : binSize : moment + postTreatmentPeriod;
                
                % Calculate PSTH
                psthCounts = histcounts(spikeTimes, binEdges);

                % Store PSTH data
                psthData.(groupName).(unitID).PSTH = psthCounts;
                psthData.(groupName).(unitID).ResponseType = unitData.ResponseType;
                psthData.(groupName).(unitID).BinEdges = binEdges;
            end
        end
    end
end
