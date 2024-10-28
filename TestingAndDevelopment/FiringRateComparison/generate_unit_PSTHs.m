function responsive_units_struct = generate_unit_PSTHs(responsive_units_struct, params, saveDir)
    % Generates full-recording and time-locked PSTHs for each unit and stores them in the struct.
    % Saves the plots as a PDF in the specified directory.

    % Define PDF save path
    pdfFilePath = fullfile(saveDir, 'aligned_spike_data.pdf');
    fig = figure('Visible', 'off', 'Position', [100, 100, 1200, 800]);

    % Iterate over all groups, recordings, and units
    groupNames = fieldnames(responsive_units_struct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(responsive_units_struct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(responsive_units_struct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                % Process and store PSTHs
                [fullPSTH, fullBinEdges] = compute_full_PSTH(unitData, params);
                [labelPSTH, labelBinEdges, alignedSpikeTimes] = compute_label_PSTH(unitData, params);

                % Store computed data in the struct
                responsive_units_struct.(groupName).(recordingName).(unitID).PSTH_Full = fullPSTH;
                responsive_units_struct.(groupName).(recordingName).(unitID).Full_BinEdges = fullBinEdges;
                responsive_units_struct.(groupName).(recordingName).(unitID).PSTH_Label = labelPSTH;
                responsive_units_struct.(groupName).(recordingName).(unitID).Label_BinEdges = labelBinEdges;

                % Call the plotting function
                plot_unit_PSTH(fig, alignedSpikeTimes, fullBinEdges, fullPSTH, ...
                               labelBinEdges, labelPSTH, groupName, recordingName, unitID, unitData, pdfFilePath);

                % Debugging output
                fprintf('Processed %s - %s - %s\n', groupName, recordingName, unitID);
            end
        end
    end

    % Close the figure after saving all plots
    close(fig);
    fprintf('All aligned spike data saved to %s\n', pdfFilePath);
end

%% Helper Functions

%Generate PSTH for the whole recording
function [fullPSTH, binEdges] = compute_full_PSTH(unitData, params)
    % Generate PSTH for the entire recording
    spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;
    binEdges = 0:params.binSize:(90 * 60);  % 90-minute recording assumption
    fullPSTH = histcounts(spikeTimes, binEdges) / params.binSize;
end

% Generate labels for PSTHs based on pre and post firing behavior
function [labelPSTH, binEdges, alignedSpikeTimes] = compute_label_PSTH(unitData, params)
    % Generate PSTH for pre- and post-treatment periods
    spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;
    alignedSpikeTimes = spikeTimes - params.moment;
    binEdges = -params.preTreatmentPeriod:params.binSize:params.postTreatmentPeriod;
    labelPSTH = histcounts(alignedSpikeTimes, binEdges) / params.binSize;

    % Handle empty PSTH
    if isempty(labelPSTH)
        labelPSTH = zeros(1, length(binEdges) - 1);
    end
end
