function subPlotAllPSTHsRawWithMean(cellDataStruct, treatmentTime, ax)
    % subPlotAllPSTHsRawWithMean: Plots all raw PSTHs with grand average in a given subplot axis.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all group, recording, and unit PSTH data.
    %   - treatmentTime: Time (in seconds) to indicate the treatment moment.
    %   - ax: Axes handle for plotting the subplot in an existing figure.

    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 1860;  % Default treatment time in seconds
    end

    % Define color mapping for each response type
    colorMap = containers.Map({'Increased', 'Decreased', 'No Change'}, ...
                              {[1, 0, 0, 0.3], [0, 0, 1, 0.3], [0.5, 0.5, 0.5, 0.3]}); % RGBA format with transparency

    % Call calculateGrandPSTH to get grand average and time vector
    [grandAveragePSTH, timeVector] = calculateGrandPSTH(cellDataStruct);
    
    % Plot individual unit PSTHs with color coding based on response type
    hold(ax, 'on'); % Hold on for overlaying plots in the specified axes
    groupNames = fieldnames(cellDataStruct);

    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Check for required fields
                if isfield(unitData, 'psthRaw') && isfield(unitData, 'responseType')
                    psth = unitData.psthRaw;

                    % Set color based on response type
                    responseType = unitData.responseType;
                    if isKey(colorMap, responseType)
                        colorVal = colorMap(responseType);
                        plot(ax, timeVector, psth, 'Color', colorVal, 'LineWidth', 0.5);
                    end
                end
            end
        end
    end

    % Plot the grand average PSTH
    plot(ax, timeVector, grandAveragePSTH, 'k-', 'LineWidth', 2);

    % Add treatment line, labels, and title
    xline(ax, treatmentTime, '--g', 'LineWidth', 1.5, 'DisplayName', 'Treatment Time');
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Firing Rate (spikes/s)');
    title(ax, 'All Units with Grand Average PSTH');
    legend(ax, 'Average PSTH', 'Location', 'Best');
    hold(ax, 'off');
end
