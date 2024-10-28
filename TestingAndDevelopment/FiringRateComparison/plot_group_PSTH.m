function plot_group_PSTH(responsive_units_struct, params)
    colormapList = lines(10);  % Generate 10 unique colors

    groupNames = fieldnames(responsive_units_struct);

    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(responsive_units_struct.(groupName));
        numRecordings = length(recordings);
        recordingColors = colormapList(1:numRecordings, :);

        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');
        responseTypes = {'Increased', 'Decreased', 'NoChange'};

        for rt = 1:length(responseTypes)
            responseType = responseTypes{rt};

            subplot(1, 3, rt);
            hold on;
            title([groupName, ' - ', responseType], 'Interpreter', 'none');
            xlabel('Time (ms)');
            ylabel('Firing Rate (Hz)');

            unitsPlotted = false;

            for r = 1:numRecordings
                recordingName = recordings{r};
                units = fieldnames(responsive_units_struct.(groupName).(recordingName));

                for u = 1:length(units)
                    unitID = units{u};
                    unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                    disp(['Processing unit: ', unitID, ', ResponseType: ', unitData.ResponseType]);

                    if isfield(unitData, 'PSTH') && strcmp(unitData.ResponseType, responseType)
                        color = recordingColors(r, :);
                        smoothedPSTH = conv(unitData.PSTH, params.smoothingWindow, 'same');

                        timeBins = linspace(0, length(smoothedPSTH) - 1, length(smoothedPSTH)) * params.binSize * 1000;

                        plot(timeBins, smoothedPSTH, 'Color', color, 'LineWidth', 1.5);
                        text(timeBins(end), smoothedPSTH(end), unitID, 'FontSize', 8, 'Interpreter', 'none');
                        unitsPlotted = true;
                    end
                end
            end

            if ~unitsPlotted
                text(0.5, 0.5, 'No units for this response type', 'HorizontalAlignment', 'center', 'Units', 'normalized');
            end

            hold off;
        end
    end
end



