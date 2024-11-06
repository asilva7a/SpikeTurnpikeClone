function subPlotExperimentalvsControl(cellDataStruct, ax)
    % plotResponsiveUnitsWithAverages: Plots the responsive units from experimental groups with
    % color-coded PSTHs, along with the average and SEM for both experimental and control groups.
    %
    % Inputs:
    %   - ax: Axis handle where the subplot will be plotted.
    %   - cellDataStruct: Data structure containing pooled responses for control and experimental groups.

    % Define color mapping for response types
    colorMap = containers.Map({'Increased', 'Decreased'}, ...
                              {[1, 0, 0, 0.3], [0, 0, 1, 0.3]}); % Red for Increased, Blue for Decreased

    % Clear axis and hold for overlaying multiple plots
    cla(ax);
    hold(ax, 'on');

    % Extract the pooled PSTH and SEM for control and experimental groups
    controlAvgPSTH = cellDataStruct.expData.Control.pooledResponses.avgPSTH;
    controlSEMPSTH = cellDataStruct.expData.Control.pooledResponses.semPSTH;
    expAvgPSTH = cellDataStruct.expData.Experimental.pooledResponses.avgPSTH;
    expSEMPSTH = cellDataStruct.expData.Experimental.pooledResponses.semPSTH;
    timeVector = cellDataStruct.expData.Control.pooledResponses.timeVector;

    % Plot individual responsive units from the experimental groups
    experimentalGroups = {'emx', 'pvalb'};
    for i = 1:numel(experimentalGroups)
        groupName = experimentalGroups{i};
        recordingNames = fieldnames(cellDataStruct.(groupName));

        % Loop through recordings and units to plot each responsive unit
        for r = 1:numel(recordingNames)
            units = fieldnames(cellDataStruct.(groupName).(recordingNames{r}));
            units(strcmp(units, 'recordingData')) = [];  % Exclude `recordingData`

            for u = 1:numel(units)
                unitData = cellDataStruct.(groupName).(recordingNames{r}).(units{u});
                if isfield(unitData, 'responseType') && isfield(unitData, 'psthSmoothed')
                    responseType = unitData.responseType;
                    
                    % Only plot if the unit is responsive (e.g., "Increased" or "Decreased")
                    if isKey(colorMap, responseType)
                        colorVal = colorMap(responseType);  % Get RGBA color
                        lineColor = colorVal(1:3);          % Extract RGB
                        alphaVal = colorVal(4);             % Extract alpha (transparency)
                        
                        % Plot the individual PSTH with specified color and transparency
                        plot(ax, timeVector, unitData.psthSmoothed, 'Color', [lineColor, alphaVal], 'LineWidth', 0.5);
                    end
                end
            end
        end
    end

    % Plot the SEM shading around the average PSTH for the experimental group
    fill(ax, [timeVector, fliplr(timeVector)], ...
         [expAvgPSTH + expSEMPSTH, fliplr(expAvgPSTH - expSEMPSTH)], ...
         [0, 0, 0], 'FaceAlpha', 0.2, 'EdgeColor', 'none');  % Shaded area in black for SEM

    % Plot the average PSTH for the experimental group (black line)
    plot(ax, timeVector, expAvgPSTH, 'k-', 'LineWidth', 2, 'DisplayName', 'Experimental Avg PSTH');

    % Plot the SEM shading around the average PSTH for the control group
    fill(ax, [timeVector, fliplr(timeVector)], ...
         [controlAvgPSTH + controlSEMPSTH, fliplr(controlAvgPSTH - controlSEMPSTH)], ...
         [0.5, 0.5, 0.5], 'FaceAlpha', 0.2, 'EdgeColor', 'none');  % Shaded area in gray for SEM

    % Plot the average PSTH for the control group (gray line)
    plot(ax, timeVector, controlAvgPSTH, 'Color', [0.5, 0.5, 0.5], 'LineWidth', 2, 'DisplayName', 'Control Avg PSTH');

    % Add labels and title
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Firing Rate (spikes/s)');
    title(ax, 'Responsive Units from Experimental Groups with Average PSTH and SEM');

    % Legend to differentiate lines
    legend(ax, 'Experimental Avg PSTH', 'Control Avg PSTH', 'Location', 'northeastoutside');

    % Set axis limits
    ylim(ax, [0 inf]);  % Start y-axis at 0 and let it auto-adjust
    xlim(ax, [0 max(timeVector)]); % Use the maximum time from the time vector

    hold(ax, 'off');
end
