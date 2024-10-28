function psthData = generate_unit_PSTHs(responsive_units_struct, all_data, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Initialize storage structure for PSTHs
    psthData = struct();

    % Get group names from the responsive_units_struct
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

                % Cross-reference with all_data to get SpikeTimes_all
                if isfield(all_data.(groupName), recordingName) && ...
                   isfield(all_data.(groupName).(recordingName), unitID)

                    % Access the unit data from all_data
                    unitData = all_data.(groupName).(recordingName).(unitID);

                    % Ensure SpikeTimes_all is available
                    if isfield(unitData, 'SpikeTimes_all') && ~isempty(unitData.SpikeTimes_all)
                        % Extract spike times and normalize by sampling frequency
                        spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                        % Define bin edges
                        binEdges = moment - preTreatmentPeriod : binSize : moment + postTreatmentPeriod;

                        % Calculate PSTH
                        psthCounts = histcounts(spikeTimes, binEdges);

                        % Store PSTH data
                        psthData.(groupName).(unitID).PSTH = psthCounts;
                        psthData.(groupName).(unitID).ResponseType = ...
                            responsive_units_struct.(groupName).(recordingName).(unitID).ResponseType;
                        psthData.(groupName).(unitID).BinEdges = binEdges;
                    else
                        warning('Missing or empty spike times for unit %s. Skipping.', unitID);
                    end
                else
                    warning('Unit %s not found in all_data. Skipping.', unitID);
                end
            end
        end
    end
end
