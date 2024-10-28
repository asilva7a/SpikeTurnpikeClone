function responsive_units_struct = generate_unit_PSTHs(responsive_units_struct, params)
    % This function generates both full-recording and labeling PSTHs.

    groupNames = fieldnames(responsive_units_struct);  % Get group names

    for g = 1:length(groupNames)
        groupName = groupNames{g};  % Use curly braces to index the cell array
        recordings = fieldnames(responsive_units_struct.(groupName));  % Get recordings

        for r = 1:length(recordings)
            recordingName = recordings{r};  % Use curly braces here too
            units = fieldnames(responsive_units_struct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                % Extract and align spike times with the moment
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;
                alignedSpikeTimes = spikeTimes - params.moment;

                % Plot to debug alignment (optional)
                figure;
                plot(alignedSpikeTimes, 'o');
                xlabel('Spike Index');
                ylabel('Time Relative to Moment (s)');
                title(sprintf('Aligned Spike Times for %s - %s', recordingName, unitID));

                % Full Recording PSTH
                fullBinEdges = 0:params.binSize:max(spikeTimes);
                fullPSTH = histcounts(spikeTimes, fullBinEdges);

                % Store full PSTH in the struct
                responsive_units_struct.(groupName).(recordingName).(unitID).PSTH_Full = fullPSTH;
                responsive_units_struct.(groupName).(recordingName).(unitID).Full_BinEdges = fullBinEdges;

                % Labeling PSTH (Pre- and Post-Treatment)
                labelBinEdges = -params.preTreatmentPeriod:params.binSize:params.postTreatmentPeriod;
                labelPSTH = histcounts(alignedSpikeTimes, labelBinEdges);

                % Store labeling PSTH in the struct
                responsive_units_struct.(groupName).(recordingName).(unitID).PSTH_Label = labelPSTH;
                responsive_units_struct.(groupName).(recordingName).(unitID).Label_BinEdges = labelBinEdges;

                % Check if PSTHs are empty
                if all(labelPSTH == 0)
                    warning('Labeling PSTH for unit %s is empty.', unitID);
                end
                if all(fullPSTH == 0)
                    warning('Full-recording PSTH for unit %s is empty.', unitID);
                end

                % Debugging Output: Verify Data Access
                fprintf('Processed %s - %s - %s\n', groupName, recordingName, unitID);
                disp(['First aligned spike: ', num2str(min(alignedSpikeTimes))]);
                disp(['Last aligned spike: ', num2str(max(alignedSpikeTimes))]);
                disp(['Full Bin Edges: ', num2str(fullBinEdges(1)), ' to ', num2str(fullBinEdges(end))]);
                disp(['Label Bin Edges: ', num2str(labelBinEdges(1)), ' to ', num2str(labelBinEdges(end))]);
            end
        end
    end
end


    


