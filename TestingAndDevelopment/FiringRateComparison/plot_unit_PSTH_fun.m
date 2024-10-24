function plot_unit_PSTH(smoothedCounts, cellID, cellData)
    % Extract necessary metadata
    templateChannel = cellData.Template_Channel;  % Use Template_Channel instead of Channel
    recordingName = 'Unknown';  % Handle missing Recording_Name gracefully
    if isfield(cellData, 'Recording_Name')
        recordingName = cellData.Recording_Name;
    end

    % Create the plot
    figure;
    plot(smoothedCounts, 'k', 'LineWidth', 1.5);  % Plot PSTH in black

    % Add metadata to the plot title
    title(sprintf('Unit: %s | Type: %s | Channel: %d | Recording: %s', ...
        cellID, cellData.Cell_Type, templateChannel, recordingName));
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    axis tight;  % Fit the plot tightly to the data
end

