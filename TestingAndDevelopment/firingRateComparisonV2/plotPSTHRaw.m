function plotPSTH(binEdges, fullPSTH, lineTime, figTitle)
    % plotPSTH - Plots the Peri-Stimulus Time Histogram (PSTH)
    % 
    % Inputs:
    %   binEdges  - Array of bin edges used for the histogram
    %   fullPSTH  - Array of firing rates (spikes per second) for each bin
    %   lineTime  - Time in seconds where a vertical line is drawn (optional)
    %   figTitle  - Title of the plot (optional)
    %
    % Example:
    %   plotPSTH(binEdges, fullPSTH, 1800, 'PSTH Example');

    % Create a new figure
    figure;

    % Plot the PSTH with black bars and edges
    bar(binEdges(1:end-1), fullPSTH, 'histc', 'FaceColor', 'k', 'EdgeColor', 'k'); 

    % Add labels and title
    xlabel('Time (s)');
    ylabel('Firing Rate (spikes/s)');
    
    % Add title if provided
    if nargin > 3 && ~isempty(figTitle)
        title(figTitle);
    else
        title('Peri-Stimulus Time Histogram (PSTH)');
    end

    % Add a red dotted line at the specified time, if provided
    if nargin > 2 && ~isempty(lineTime)
        hold on;  % Keep the bar plot to overlay the line
        xline(lineTime, 'r--', 'LineWidth', 2);  % Red dotted line
    end

    % Optional: Improve plot appearance
    grid off;
    set(gca, 'Box', 'off', 'TickDir', 'out');  % Clean up plot look
end

