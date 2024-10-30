function [smoothedPSTH_Lineplot,rawPSTH_Lineplot] = plotPSTHLines(cellDataStruct)

    % Extract variable info
    binEdges = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.binEdges;
    rawPSTH = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.psthRaw;
    smoothedPSTH = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.psthSmoothed;

    % Calculate bin centers
    binCenters = binEdges(1:end-1) + diff(binEdges) / 2;

    % Create a new figure
    figure;
    hold on;

    % Plot raw PSTH as a black line
    plot(binCenters, rawPSTH, '-k', 'LineWidth', 1.5, 'DisplayName', 'Raw PSTH');

    % Plot smoothed PSTH as a red line
    plot(binCenters, smoothedPSTH, '-r', 'LineWidth', 2, 'DisplayName', 'Smoothed PSTH');

    % Add labels, title, and legend
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    title('Raw and Smoothed PSTH as Continuous Lines');
    legend('Location', 'best');

    % Finalize the plot
    hold off;
end


