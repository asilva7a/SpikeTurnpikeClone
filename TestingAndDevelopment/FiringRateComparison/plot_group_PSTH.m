function plot_group_PSTH(responsive_units_struct, params)
    % Define a colormap for different recordings
    colormapList = lines(10);  % Generate 10 unique colors

    % Get the group names (e.g., 'Control', 'Emx', 'Pvalb')
    groupNames = fieldnames(responsive_units_struct);

    % Iterate over all groups
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(responsive_units_struct.(groupName));  % Get recordings

        % Assign each recording a unique color
        numRecordings = length(recordings);
        recordingColors = colormapList(1:numRecordings, :);  % Ensure enough colors

        % Create a new figure for this group
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');

        % Define response types
        responseTypes = {'Increased', 'Decreased', 'NoChange'};

        % Iterate over response types to plot them in corresponding subplots
        for rt = 1:length(responseTypes)
            responseType = responseTypes{rt};

            % Create a subplot for the current response type
            subplot(1, 3, rt);
            hold on;
            title([groupName, ' - ', responseType], 'Interpreter', 'none');
            xlabel('Time (ms)');
            ylabel('Firing Rate (Hz)');

            % Track if any units were plotted
            unitsPlotted = false;

            % Iterate over all recordings in the group
            for r = 1:numRecordings
                recordingName = recordings{r};
                units = fieldnames(responsive_units_struct.(groupName).(recordingName));

                % Iterate over units in the current recording
                for u = 1:length(units)
                    unitID = units{u};
                    unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                    % Debugging: Display the unit data fields
                    disp(['Processing unit: ', unitID]);
                    disp(['Response type: ', unitData.ResponseType]);
                    disp('PSTH data:');
                    disp(unitData.PSTH);  % Ensure PSTH is valid and not empty

                    % Ensure the unit has the necessary fields
                    if ~isfield(unitData, 'PSTH') || ~isfield(unitData, 'ResponseType')
                        warning('Skipping unit %s: Missing PSTH or ResponseType field.', unitID);
                        continue;
                    end

                    % Check if the unit matches the current response type
                    if strcmp(unitData.ResponseType, responseType)
                        % Get the color for the current recording
                        color = recordingColors(r, :);

                        % Smooth the PSTH data
                        smoothedPSTH = conv(unitData.PSTH, params.smoothingWindow, 'same');

                        % Plot the PSTH with the appropriate color
                        plot(smoothedPSTH, 'Color', color, 'LineWidth', 1.5);

                        % Optionally, add unit ID as text annotation
                        text(length(smoothedPSTH), smoothedPSTH(end), unitID, ...
                             'FontSize', 8, 'Interpreter', 'none');

                        % Mark that a unit was plotted
                        unitsPlotted = true;
                    end
                end
            end

            % If no units were plotted, display a message
            if ~unitsPlotted
                text(0.5, 0.5, 'No units for this response type', ...
                    'HorizontalAlignment', 'center', 'Units', 'normalized');
            end

            hold off;
        end
    end
end

