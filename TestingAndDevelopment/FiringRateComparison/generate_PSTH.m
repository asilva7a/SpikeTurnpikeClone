function generate_unit_PSTHs(all_data, binSize, smoothingWindow)
    % Generate time-locked PSTHs for each unit across the entire recording.
    % The PSTHs are plotted individually with relevant metadata for sanity checking.
    %
    % INPUTS:
    %   all_data       - Structure containing spike data for groups, recordings, and units.
    %   binSize        - Size of time bins for PSTH (in seconds).
    %   smoothingWindow- A vector specifying the smoothing window (e.g., [1 1 1 1 1]).
    %
    % Each plot will display:
    %   - Unit ID
    %   - Unit type (e.g., RS or FS)
    %   - Channel number
    %   - Recording name
    %   - Whether the unit was modulated (Increased/Decreased/No Change)

    % Define a figure counter to manage plot layout
    figCounter = 1;  % Keeps track of how many figures we generate
    unitsPerFigure = 10;  % Number of subplots per figure window

    % Iterate through all groups, recordings, and units
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            unitNames = fieldnames(all_data.(groupName).(recordingName));

            for u = 1:length(unitNames)
                unitName = unitNames{u};
                unitData = all_data.(groupName).(recordingName).(unitName);

                % Extract spike times (in seconds)
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                % Generate bin edges based on the entire recording duration
                edges = 0:binSize:unitData.Recording_Duration;  % Bin edges

                % Compute PSTH (spike counts per bin, raw firing rate in Hz)
                psthCounts = histcounts(spikeTimes, edges) / binSize;  % In Hz

                % Apply light smoothing using the provided smoothing window
                smoothedPSTH = conv(psthCounts, smoothingWindow, 'same');

                % Check if a new figure is needed
                if mod(u - 1, unitsPerFigure) == 0
                    figure(figCounter);  % Create a new figure
                    figCounter = figCounter + 1;
                    clf;  % Clear the figure for fresh plotting
                    tiledlayout(unitsPerFigure / 2, 2);  % Create a grid layout
                end

                % Plot the PSTH for the current unit
                nexttile;
                plot(edges(1:end-1), smoothedPSTH, 'k', 'LineWidth', 1.5);
                xlabel('Time (s)');
                ylabel('Firing Rate (Hz)');

                % Add metadata to the plot title
                title(sprintf('Unit: %s | Type: %s | Ch: %d | Rec: %s | Mod: %s', ...
                    unitName, unitData.Cell_Type, unitData.Template_Channel, ...
                    recordingName, unitData.ResponseType));
                
                % Adjust y-axis limits for better visualization
                ylim([0, max(smoothedPSTH) + 0.1 * max(smoothedPSTH)]);  
            end
        end
    end
end
