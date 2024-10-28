function plot_unit_PSTH_fun(fig, alignedSpikeTimes, fullBinEdges, fullPSTH, ...
                        labelBinEdges, labelPSTH, groupName, recordingName, ...
                        unitID, unitData, pdfFilePath)
    % Clear the figure for the next plot
    clf;

    % Plot aligned spike times
    subplot(3, 1, 1);
    plot(alignedSpikeTimes, 'o');
    xlabel('Spike Index');
    ylabel('Time Relative to Treatment (s)');
    title(sprintf('Aligned Spikes: %s - %s', recordingName, unitID));

    % Plot full recording PSTH
    subplot(3, 1, 2);
    plot(fullBinEdges(1:end-1), fullPSTH, 'r');
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    title(sprintf('Full Recording PSTH: %s - %s', recordingName, unitID));

    % Plot label PSTH (pre/post treatment)
    subplot(3, 1, 3);
    plot(labelBinEdges(1:end-1), labelPSTH, 'b');
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    title(sprintf('Label PSTH: %s - %s', recordingName, unitID));

    % Annotation with metadata
    annotation('textbox', [0.1, 0.05, 0.8, 0.1], 'String', ...
               sprintf('Group: %s | Recording: %s | Unit: %s | Cell Type: %s | Response: %s', ...
                       groupName, recordingName, unitID, unitData.Cell_Type, unitData.ResponseType), ...
               'HorizontalAlignment', 'center', 'FitBoxToText', 'on');

    % Save the figure to the PDF
    exportgraphics(fig, pdfFilePath, 'Append', true);
end
