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
    f = figure;

    % Plot the PSTH with black bars and edges
    bar(binEdges(1:end-1), fullPSTH, 'FaceColor', 'k', 'EdgeColor', 'k');

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

    % Define the unit name and generate the current date string
    unitName = 'cid0';  % Replace with the actual unit name
    dateStr = datestr(now, 'yyyy-mm-dd_HH-MM');  % Format: YYYY-MM-DD_HH-MM
    
    % Construct the file name (save directory + name + extension)
    saveDir = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';  % Replace with desired directory
    fileName = sprintf('RawPSTH-%s_%s.png', unitName, dateStr);  % e.g., 'RawPSTH-unit_001_2024-10-30_13-45.png'
    fullPath = fullfile(saveDir, fileName);
    
    % Save the figure as a PNG with high resolution
    exportgraphics(f, fullPath, 'Resolution', 300);  % Save with 300 DPI

end

