function plot_unit_PSTH(smoothedCounts, cellID, cellData)
    % Plot the PSTH for a single unit with metadata.

    figure;
    plot(smoothedCounts, 'k', 'LineWidth', 1.5);  % Plot PSTH in black

    % Add metadata to the plot
    title(sprintf('Unit: %s | Type: %s | Channel: %d | Recording: %s', ...
        cellID, cellData.Cell_Type, cellData.Channel, cellData.Recording_Name));
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    axis tight;  % Fit the plot tightly
end
