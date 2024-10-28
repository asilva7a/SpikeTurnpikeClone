function psthData = generate_unit_PSTHs(responsive_units_struct, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    % This function generates PSTHs for each unit in the provided data and
    % stores them in a structured output for future plotting.

    % Initialize storage structure for PSTHs
    psthData = struct();

    % Get group names from the responsive units struct
    groupNames = fieldnames(responsive_units_struct);

    % Iterate over all groups
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        groupData = responsive_units_struct.(groupName);
        
        % Get the recording names within the group
        recordingNames = fieldnames(groupData);

        % Iterate over recordings within the group
        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            recordingData = groupData.(recordingName);

            % Get the unit IDs within the recording
            unitIDs = fieldnames(recordingData);

            % Initialize the group field in the output struct
            if ~isfield(psthData, groupName)
                psthData.(groupName) = struct();
            end

            % Iterate over units in the recording
            for u = 1:length(unitIDs)
                unitID = unitIDs{u};
                unitData = recordingData.(unitID);

                % Ensure the required fields exist
                if ~isfield(unitData, 'SpikeTimes_all') || ~isfield(unitData, 'ResponseType')
                    warning('Missing data for unit %s. Skipping.', unitID);
                    continue;
                end

                % Extract spike times and calculate the PSTH
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;
                binEdges = moment - preTreatmentPeriod : binSize : moment + postTreatmentPeriod;
                psthCounts = histcounts(spikeTimes, binEdges);

                % Store the PSTH data in the output structure
                psthData.(groupName).(unitID).PSTH = psthCounts;
                psthData.(groupName).(unitID).ResponseType = unitData.ResponseType;
                psthData.(groupName).(unitID).BinEdges = binEdges;
                psthData.(groupName).(unitID).Recording = recordingName;
            end
        end
    end
end
