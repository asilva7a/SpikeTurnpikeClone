function psthData = generate_unit_PSTHs(responsive_units_struct, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Initialize storage structure for PSTHs
    psthData = struct();

    % Get group names from responsive_units_struct
    groupNames = fieldnames(responsive_units_struct);

    % Iterate over groups
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(responsive_units_struct.(groupName));

        % Initialize group in the output structure
        psthData.(groupName) = struct();

        % Iterate over recordings in the group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(responsive_units_struct.(groupName).(recordingName));

            % Iterate over units in the recording
            for u = 1:length(units)
                unitID = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                % Extract spike times and sampling frequency
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                % Define bin edges for the PSTH
                binEdges = moment - preTreatmentPeriod : binSize : moment + postTreatmentPeriod;

                % Calculate the PSTH
                psthCounts = histcounts(spikeTimes, binEdges);

                % Store PSTH data in the output structure
                psthData.(groupName).(unitID) = struct(...
                    'PSTH', psthCounts, ...
                    'ResponseType', unitData.ResponseType, ...
                    'BinEdges', binEdges, ...
                    'Recording', recordingName);
            end
        end
    end
end
