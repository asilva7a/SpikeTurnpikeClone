function psthData = generate_unit_PSTHs(responsive_units_struct, params)
    % Initialize storage structure for PSTHs
    psthData = struct();

    % Get unique group names from the responsive units struct
    groupNames = fieldnames(responsive_units_struct);

    % Iterate over all groups
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        disp(['Processing group: ', groupName]);  % Debug

        recordings = fieldnames(responsive_units_struct.(groupName));

        % Iterate over each recording in the group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            disp(['  Processing recording: ', recordingName]);  % Debug

            units = fieldnames(responsive_units_struct.(groupName).(recordingName));

            % Iterate over units within the recording
            for u = 1:length(units)
                unitID = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                disp(['    Processing unit: ', unitID]);  % Debug

                % Extract spike times and sampling frequency
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;
                disp(['    SpikeTimes length: ', num2str(length(spikeTimes))]);  % Debug

                % Define bin edges
                binEdges = params.moment - params.preTreatmentPeriod : params.binSize : ...
                           params.moment + params.postTreatmentPeriod;
                disp(['    Bin edges: ', num2str(binEdges(1:5)), ' ...']);  % Debug
                
                if isempty(spikeTimes) || spikeTimes(1) < binEdges(1) || spikeTimes(end) > binEdges(end)
                    warning('Spike times for unit %s are out of binning range.', unitID);
                    continue;
                end
                
                % Calculate PSTH
                psthCounts = histcounts(spikeTimes, binEdges);
                if all(psthCounts == 0)
                    warning('    PSTH for unit %s is empty.', unitID);
                end

                % Store the PSTH in the output structure
                psthData.(groupName).(recordingName).(unitID).PSTH = psthCounts;
                psthData.(groupName).(recordingName).(unitID).BinEdges = binEdges;
                psthData.(groupName).(recordingName).(unitID).ResponseType = unitData.ResponseType;
            end
        end
    end
end
