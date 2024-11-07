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
    
    % Hold on for overlaying plots in the specified axes
    hold(ax, 'on'); 

    % Prepare dummy handles for the legend
    legendHandles = [];
    legendLabels = {'Increased', 'Decreased', 'No Change'};

    % Plot dummy lines for each response type to add to the legend
    for k = 1:numel(legendLabels)
        responseType = legendLabels{k};
        colorVal = colorMap(responseType);
        h = plot(ax, NaN, NaN, '-', 'Color', colorVal, 'LineWidth', 0.5); % Dummy line
        legendHandles = [legendHandles, h]; %#ok<AGROW>
    end

    % Loop through each group and recording to plot individual unit PSTHs
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

    % Plot the grand average PSTH and save the handle
    hGrandAvg = plot(ax, timeVector, grandAveragePSTH, 'k-', 'LineWidth', 2, 'DisplayName', 'Grand Average PSTH');

    % Plot the treatment line and save the handle
    hTreatment = xline(ax, treatmentTime, '--g', 'LineWidth', 1.5, 'DisplayName', 'Treatment Time');

    % Add labels, title, and axis limits
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Firing Rate (spikes/s)');
    title(ax, 'All Units with Grand Average PSTH');
    xlim(ax, [0, 5400]); % Set the x-axis limit to 5400 seconds

    % Create the legend
    legend([legendHandles, hGrandAvg, hTreatment], {'Increased', 'Decreased', 'No Change', 'Grand Average PSTH', 'Treatment Time'}, ...
           'Location', 'best');

    % Release the hold on the axis
    hold(ax, 'off');
end
