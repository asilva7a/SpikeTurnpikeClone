function [subPlot1] = subPlotAllPSTHsRawWithMean(cellDataStruct, treatmentTime, ax)
    % subPlotAllPSTHsRawWithMean: Plots all raw PSTHs with group average in a given subplot axis.
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

    % Prepare array for collecting all unit PSTHs
    allPSTHs = [];
    timeVector = [];
    totalUnits = 0;

    % Loop through groups, recordings, and units to gather PSTHs
    groupNames = fieldnames(cellDataStruct);
    hold(ax, 'on'); % Hold on for overlaying plots in the specified axes

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
                    binEdges = unitData.binEdges;
                    binWidth = unitData.binWidth;
                    timeVector = binEdges(1:end-1) + binWidth / 2;

                    % Store PSTH data for averaging
                    if isempty(allPSTHs)
                        allPSTHs = NaN(numel(units), length(psth));
                    end
                    allPSTHs(totalUnits + 1, :) = psth;
                    totalUnits = totalUnits + 1;

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

    % Calculate the grand average PSTH across all units and plot it
    grandAveragePSTH = mean(allPSTHs, 1, 'omitnan');
    plot(ax, timeVector, grandAveragePSTH, 'k-', 'LineWidth', 2);

    % Add treatment line, labels, and title
    xline(ax, treatmentTime, '--g', 'LineWidth', 1.5, 'DisplayName', 'Treatment Time');
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Firing Rate (spikes/s)');
    title(ax, 'All Units with Grand Average PSTH');
    legend(ax, 'Average PSTH', 'Location', 'Best');
    hold(ax, 'off');
end

