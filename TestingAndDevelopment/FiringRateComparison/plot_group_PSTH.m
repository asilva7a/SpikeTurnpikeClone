function plot_group_PSTH(psthData, data_table_FR, smoothingWindow)
    % Define a colormap for different recordings
    colormapList = lines(10);  % Generate 10 unique colors

    % Get the group names (e.g., 'Control', 'Emx', 'Pvalb')
    groupNames = fieldnames(psthData);

    % Iterate over all groups
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        units = psthData.(groupName);  % Extract the struct for the current group
        unitIDs = fieldnames(units);   % Get unit IDs within the group

        % Filter `data_table_FR` for the current group
        groupTable = data_table_FR(strcmp(data_table_FR.Group, groupName), :);
        recordings = unique(groupTable.Recording);  % Unique recording names
        numRecordings = length(recordings);

        % Assign each recording a unique color
        recordingColors = colormapList(1:numRecordings, :);  % Ensure enough colors

        % Create a new figure for this group
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');

        % Create a 1x3 layout: one subplot for each response type
        responseTypes = {'Increased', 'Decreased', 'NoChange'};

        % Iterate over response types to plot them in the corresponding subplot
        for rt = 1:3
            responseType = responseTypes{rt};

            % Create a subplot for the current response type
            subplot(1, 3, rt);
            hold on;
            title([groupName, ' - ', responseType], 'Interpreter', 'none');
            xlabel('Time (ms)');
            ylabel('Firing Rate (Hz)');

            % Plot units belonging to the current response type
            for u = 1:length(unitIDs)
                unitID = unitIDs{u};
                unitData = units.(unitID);  % Extract unit data

                % Ensure the unit has the required fields
                if ~isfield(unitData, 'PSTH') || ~isfield(unitData, 'ResponseType')
                    warning('Skipping unit %s: Missing PSTH or ResponseType field.', unitID);
                    continue;
                end

                % Check if the unit belongs to the current response type
                if strcmp(unitData.ResponseType, responseType)
                    % Find the recording name for the unit from `data_table_FR`
                    recordingName = groupTable{strcmp(groupTable.UnitID, unitID), 'Recording'}{1};

                    % Get the color for the unit's recording
                    recordingIdx = find(strcmp(recordings, recordingName));
                    color = recordingColors(recordingIdx, :);

                    % Smooth the PSTH data
                    smoothedPSTH = conv(unitData.PSTH, smoothingWindow, 'same');

                    % Plot the PSTH with the appropriate color
                    plot(smoothedPSTH, 'Color', color, 'LineWidth', 1.5);

                    % Optionally, add unit ID as text annotation
                    text(length(smoothedPSTH), smoothedPSTH(end), unitID, ...
                         'FontSize', 8, 'Interpreter', 'none');
                end
            end
            hold off;
        end
    end
end

