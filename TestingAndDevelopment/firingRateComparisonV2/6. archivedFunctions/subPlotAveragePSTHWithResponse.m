function subPlotAveragePSTHWithResponse(cellDataStruct, ax, groupName, recordingName, treatmentTime)
    % subPlotAveragePSTHWithResponse: Plots the average smoothed PSTH with individual units and SEM.
    % Inputs:
    %   - ax: Axis handle where the subplot will be plotted.
    %   - cellDataStruct: Data structure containing all group, recording, and unit data.
    %   - groupName (optional): Name of the group to be plotted. Defaults to the first group.
    %   - recordingName (optional): Name of the recording. Defaults to the first recording in the group.
    %   - treatmentTime: Time in seconds where treatment was administered.

    % Set default treatment time if not provided
    if nargin < 5
        treatmentTime = 1860;  % Default treatment time in seconds
    end

    % Default to first group if groupName is not specified
    if nargin < 3 || isempty(groupName)
        groupNames = fieldnames(cellDataStruct);
        groupName = groupNames{1};
    end

    % Default to first recording if recordingName is not specified
    if nargin < 4 || isempty(recordingName)
        recordingNames = fieldnames(cellDataStruct.(groupName));
        recordingNames(strcmp(recordingNames, 'groupData')) = [];  % Exclude `groupData`
        recordingName = recordingNames{1};
    end

    % Define color mapping for each response type
    colorMap = containers.Map({'Increased', 'Decreased', 'No Change'}, ...
                              {[1, 0, 0, 0.3], [0, 0, 1, 0.3], [0.5, 0.5, 0.5, 0.3]}); % RGBA format with transparency

    % Clear the axis before replotting to prevent overlap
    cla(ax);
    hold(ax, 'on');

    % Retrieve the recording-level average PSTH and SEM data
    try
        avgPSTH = cellDataStruct.(groupName).(recordingName).recordingData.avgPSTH;
        semPSTH = cellDataStruct.(groupName).(recordingName).recordingData.semPSTH;
    catch
        error('Could not find avgPSTH or semPSTH in the specified recording path: %s.%s', groupName, recordingName);
    end

    % Get the list of units in the specified recording
    units = fieldnames(cellDataStruct.(groupName).(recordingName));
    units(strcmp(units, 'recordingData')) = [];  % Exclude `recordingData` from the units list

    % Retrieve bin information from the first unit in the recording
    firstUnitID = units{1};
    try
        binEdges = cellDataStruct.(groupName).(recordingName).(firstUnitID).binEdges;
        binWidth = cellDataStruct.(groupName).(recordingName).(firstUnitID).binWidth;
        timeVector = binEdges(1:end-1) + binWidth / 2; % Use bin centers for plotting
    catch
        error('Could not find binEdges or binWidth in the first unit of recording "%s".', recordingName);
    end

    % Prepare dummy handles for legend entries for each response type
    legendHandles = [];
    responseTypes = {'Increased', 'Decreased', 'No Change'};
    for i = 1:numel(responseTypes)
        responseType = responseTypes{i};
        colorVal = colorMap(responseType);
        h = plot(ax, NaN, NaN, 'Color', colorVal, 'LineWidth', 0.5, 'DisplayName', responseType); % Dummy line
        legendHandles = [legendHandles, h]; %#ok<AGROW>
    end

    % Plot individual unit PSTHs with transparency based on response type
    for u = 1:numel(units)
        unitID = units{u};
        unitData = cellDataStruct.(groupName).(recordingName).(unitID);

        % Check if psthSmoothed and responseType are available
        if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
            psth = unitData.psthSmoothed;
            responseType = unitData.responseType;

            % Set color based on response type; skip if responseType is unknown
            if isKey(colorMap, responseType)
                colorVal = colorMap(responseType);  % Retrieve RGBA value from color map
                lineColor = colorVal(1:3);          % Extract RGB
                alphaVal = colorVal(4);             % Extract alpha (transparency)

                % Plot individual PSTH with transparency
                plot(ax, timeVector, psth, 'Color', [lineColor, alphaVal], 'LineWidth', 0.5);
            else
                % Skip plotting if the response type is not recognized
                fprintf('Unknown response type for Unit %s. Skipping plot.\n', unitID);
                continue;
            end
        end
    end

    % Plot the SEM shading around the recording-level average PSTH and save the handle
    hSEM = fill(ax, [timeVector, fliplr(timeVector)], ...
                [avgPSTH + semPSTH, fliplr(avgPSTH - semPSTH)], ...
                [0.7, 0.7, 0.7], 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % Gray shading for SEM

    % Plot the recording-level average PSTH with a solid black line and save the handle
    hAvgPSTH = plot(ax, timeVector, avgPSTH, 'k-', 'LineWidth', 2, 'DisplayName', 'Recording Mean PSTH');

    % Plot treatment line in green and save the handle
    hTreatment = xline(ax, treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5, 'DisplayName', 'Treatment Time');

    % Set axis limits
    ylim(ax, [0 inf]);  % Set y-axis lower limit to 0 and let the upper limit auto-adjust
    xlim(ax, [0 5400]); % Set x-axis upper limit to 5400 seconds

    % Add labels and title
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Firing Rate (spikes/s)');
    title(ax, sprintf('Average Smoothed PSTH with SEM'));

    % Add group and recording name annotation in the top-right corner of the plot
    text(ax, 0.98, 0.98, sprintf('%s - %s', groupName, recordingName), ...
         'Units', 'normalized', 'FontSize', 12, ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontWeight', 'bold');

    % Create the legend using specific plot handles to ensure proper labeling
    legend(ax, [legendHandles, hAvgPSTH, hSEM, hTreatment], ...
           {'Increased', 'Decreased', 'No Change', 'Recording Mean PSTH', 'SEM', 'Treatment Time'}, ...
           'Location', 'best');

    hold(ax, 'off');
end


