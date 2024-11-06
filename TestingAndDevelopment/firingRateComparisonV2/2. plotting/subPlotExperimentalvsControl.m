function subPlotExperimentalvsControl(cellDataStruct, ax)
    % subPlotExperimentalvsControl: Plots average PSTHs for control vs experimental groups with SEM shading.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing pooled responses for control and experimental groups.
    %   - ax: Axis handle where the subplot will be plotted.

    % Define colors for control and experimental groups
    controlColor = [0, 0.5, 0];      % Green
    experimentalColor = [0.5, 0, 0.5]; % Purple

    % Clear axis and hold for overlaying multiple plots
    cla(ax);
    hold(ax, 'on');

    % Extract the pooled PSTH and SEM for control and experimental groups
    controlAvgPSTH = cellDataStruct.expData.Control.pooledResponses.avgPSTH;
    controlSEMPSTH = cellDataStruct.expData.Control.pooledResponses.semPSTH;
    expAvgPSTH = cellDataStruct.expData.Experimental.pooledResponses.avgPSTH;
    expSEMPSTH = cellDataStruct.expData.Experimental.pooledResponses.semPSTH;
    timeVector = cellDataStruct.expData.Control.pooledResponses.timeVector;

    % Plot the SEM shading around the average PSTH for the control group (bottom layer)
    fill(ax, [timeVector, fliplr(timeVector)], ...
         [controlAvgPSTH + controlSEMPSTH, fliplr(controlAvgPSTH - controlSEMPSTH)], ...
         controlColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % Plot the average PSTH for the control group (green line)
    hControl = plot(ax, timeVector, controlAvgPSTH, 'Color', controlColor, 'LineWidth', 2, 'DisplayName', 'Control Avg PSTH');

    % Plot the SEM shading around the average PSTH for the experimental group (top layer)
    fill(ax, [timeVector, fliplr(timeVector)], ...
         [expAvgPSTH + expSEMPSTH, fliplr(expAvgPSTH - expSEMPSTH)], ...
         experimentalColor, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % Plot the average PSTH for the experimental group (purple line)
    hExp = plot(ax, timeVector, expAvgPSTH, 'Color', experimentalColor, 'LineWidth', 2, 'DisplayName', 'Experimental Avg PSTH');

    % Plot treatment line in green
    xline(ax, treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5, 'DisplayName', 'Treatment Time');
    
    % Add labels, title, and legend
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Firing Rate (spikes/s)');
    title(ax, 'Control vs Experimental Average PSTH with SEM');

    % Explicitly specify legend entries to ensure they match the correct colors
    legend(ax, [hExp, hControl], {'Experimental Avg PSTH', 'Control Avg PSTH'}, 'Location', 'best');

    % Set axis limits
    ylim(ax, [0 inf]);  % Start y-axis at 0 and let it auto-adjust
    xlim(ax, [0 5400]); % Set x-axis limit to maximum time

    hold(ax, 'off');
end


