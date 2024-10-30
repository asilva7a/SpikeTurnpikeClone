function [smoothedPSTH_Lineplot, rawPSTH_Lineplot] = plotPSTHLines(cellDataStruct, treatmentTime)
    % plotPSTHLines: Plots raw and smoothed PSTHs with a user-defined treatment line.
    %
    % Inputs:
    %   - cellDataStruct: Structure containing PSTH data.
    %   - treatmentTime: Time (in seconds) where the treatment was administered.
    %
    % Outputs:
    %   - smoothedPSTH_Lineplot: Handle to the smoothed PSTH line plot.
    %   - rawPSTH_Lineplot: Handle to the raw PSTH line plot.

    % Extract variables from the structure
    binEdges = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.binEdges;
    rawPSTH = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.psthRaw;
    smoothedPSTH = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.psthSmoothed;

    % Calculate bin centers (midpoints of bin edges)
    binCenters = binEdges(1:end-1) + diff(binEdges) / 2;

    % Create a new figure
    figure;
    hold on;

    % Plot raw PSTH as a black line
    rawPSTH_Lineplot = plot(binCenters, rawPSTH, '-k', 'LineWidth', 1.5, 'DisplayName', 'Raw PSTH');

    % Plot smoothed PSTH as a red line
    smoothedPSTH_Lineplot = plot(binCenters, smoothedPSTH, '-r', 'LineWidth', 2, 'DisplayName', 'Smoothed PSTH');

    % Add a vertical line at the user-specified treatment time
    xline(treatmentTime, '--b', 'Treatment', 'LineWidth', 2, ...
        'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');

    % Add labels, title, and legend
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    title('Raw and Smoothed PSTH with Treatment Line');
    legend('Location', 'best');

    % Set axis limits
    xlim([min(binEdges), max(binEdges)]);
    ylim([0, max([rawPSTH, smoothedPSTH]) * 1.1]);

    % Finalize the plot
    hold off;

    % Define the unit name and generate the current date string
    unitName = 'cid0';  % Replace with the actual unit name
    dateStr = datestr(now, 'yyyy-mm-dd_HH-MM');  % Format: YYYY-MM-DD_HH-MM
    
    % Construct the file name (save directory + name + extension)
    saveDir = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestFigures';  % Replace with desired directory
    fileName = sprintf('linePSTH-%s_%s.png', unitName, dateStr);  % e.g., 'linePSTH-unit_001_2024-10-30_13-45.png'
    fullPath = fullfile(saveDir, fileName);
    
    % Save the figure as a PNG with high resolution
    exportgraphics(f, fullPath, 'Resolution', 300);  % Save with 300 DPI
end



