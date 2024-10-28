function responsive_units_struct = generate_unit_PSTHs(responsive_units_struct, params)
    % This function generates both full-recording and labeling PSTHs.

    % Loop through all groups
    groupNames = fieldnames(responsive_units_struct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(responsive_units_struct.(groupName));  % Get recordings

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(responsive_units_struct.(groupName).(recordingName));  % Get units

            for u = 1:length(units)
                unitID = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                % Ensure necessary fields are present
                if ~isfield(unitData, 'SpikeTimes_all') || isempty(unitData.SpikeTimes_all)
                    warning('No spike times found for %s - Skipping.', unitID);
                    continue;
                end

                % Convert spike times from samples to seconds
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                % -------------------
                % 1. Full Recording PSTH
                % -------------------
                % Define bin edges for the full 90-minute recording (100ms bins)
                totalDuration = 90 * 60;  % 90 minutes in seconds
                fullBinEdges = 0:params.binSize:totalDuration;  % 100ms bins
                fullPSTH = histcounts(spikeTimes, fullBinEdges);

                % Store full PSTH in the struct
                responsive_units_struct.(groupName).(recordingName).(unitID).PSTH_Full = fullPSTH;
                responsive_units_struct.(groupName).(recordingName).(unitID).Full_BinEdges = fullBinEdges;

                % -------------------
                % 2. Labeling PSTH (Pre- and Post-Treatment)
                % -------------------
                % Align spike times relative to the moment
                alignedSpikeTimes = (unitData.SpikeTimes_all / unitData.Sampling_Frequency) - params.moment;
                
                % Debugging: Display key information
                fprintf('Group: %s | Recording: %s | Unit: %s\n', groupName, recordingName, unitID);
                fprintf('First aligned spike: %.4f | Last aligned spike: %.4f\n', ...
                        min(alignedSpikeTimes), max(alignedSpikeTimes));
                disp(['Aligned Spike Times: ', num2str(alignedSpikeTimes(1:10))]);  % Print first 10 spike times
                
                % Check if aligned spikes fall within the binning range
                if any(alignedSpikeTimes > -params.preTreatmentPeriod & alignedSpikeTimes < params.postTreatmentPeriod)
                    disp('Aligned spikes found within the bin range.');
                else
                    warning('No aligned spikes within the bin range for unit: %s', unitID);
                end
                
                % Ensure non-empty PSTHs
                if all(labelPSTH == 0)
                    warning('Labeling PSTH for unit %s is empty.', unitID);
                end
                if all(fullPSTH == 0)
                    warning('Full-recording PSTH for unit %s is empty.', unitID);
                end
            end
        end
    end
end
    


