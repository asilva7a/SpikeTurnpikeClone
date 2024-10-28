function responsive_units_struct = generate_unit_PSTHs(responsive_units_struct, params)
    % This function generates both full-recording and labeling PSTHs.
    
    for g = 1:length(fieldnames(responsive_units_struct))
        groupName = fieldnames(responsive_units_struct){g};
        recordings = fieldnames(responsive_units_struct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(responsive_units_struct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                % Extract and align spike times with the moment
                spikeTimes = (unitData.SpikeTimes_all / unitData.Sampling_Frequency);

                % -------------------
                % 1. Full Recording PSTH
                % -------------------
                fullBinEdges = 0:params.binSize:max(spikeTimes);
                fullPSTH = histcounts(spikeTimes, fullBinEdges);

                % Store full PSTH in the struct
                responsive_units_struct.(groupName).(recordingName).(unitID).PSTH_Full = fullPSTH;
                responsive_units_struct.(groupName).(recordingName).(unitID).Full_BinEdges = fullBinEdges;

                % -------------------
                % 2. Labeling PSTH (Pre- and Post-Treatment)
                % -------------------
                % Align spike times relative to the moment
                alignedSpikeTimes = spikeTimes - params.moment;

                % Define bin edges for pre- and post-treatment
                labelBinEdges = -params.preTreatmentPeriod : params.binSize : params.postTreatmentPeriod;
                labelPSTH = histcounts(alignedSpikeTimes, labelBinEdges);

                % Store labeling PSTH in the struct
                responsive_units_struct.(groupName).(recordingName).(unitID).PSTH_Label = labelPSTH;
                responsive_units_struct.(groupName).(recordingName).(unitID).Label_BinEdges = labelBinEdges;

                % Debugging output to verify data access
                fprintf('Processed %s - %s - %s\n', groupName, recordingName, unitID);
                disp(['Spike Times (Aligned): ', num2str(min(alignedSpikeTimes)), ' to ', num2str(max(alignedSpikeTimes))]);
                disp(['Full Bin Edges: ', num2str(fullBinEdges(1)), ' to ', num2str(fullBinEdges(end))]);
                disp(['Label Bin Edges: ', num2str(labelBinEdges(1)), ' to ', num2str(labelBinEdges(end))]);

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

