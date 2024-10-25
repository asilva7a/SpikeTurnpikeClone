function plot_group_PSTH(psthData, smoothingWindow)
    % Define colors for response types
    colors = struct('Increased', [1, 0, 0], ...  % Red
                    'Decreased', [0, 0, 1], ...  % Blue
                    'NoChange', [0, 0, 0]);      % Black

    % Get the group names (e.g., 'Control', 'Emx', 'Pvalb')
    groupNames = fieldnames(psthData);

    % Iterate over all groups
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        units = psthData.(groupName);  % Extract the struct for the current group

        % Get unit names (unit IDs) within the group
        unitIDs = fieldnames(units);

        % Create a new figure for this group
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');

        % Iterate over each unit within the group
        for u = 1:length(unitIDs)
            unitID = unitIDs{u};
            unitData = units.(unitID);  % Extract the data for the current unit

            % Ensure the unit has the required fields
            if ~isfield(unitData, 'PSTH') || ~isfield(unitData, 'ResponseType')
                warning('Skipping unit %s: Missing PSTH or ResponseType field.', unitID);
                continue;
            end

            % Smooth the PSTH data
            smoothedPSTH = conv(unitData.PSTH, smoothingWindow, 'same');

            % Create a subplot for this unit
            subplot(ceil(length(unitIDs) / 5), 5, u);  % Adjust layout as needed
            hold on;

            % Plot the PSTH with the appropriate color
            responseType = unitData.ResponseType;
            if isfield(colors, responseType)
                plot(smoothedPSTH, 'Color', colors.(responseType), 'LineWidth', 1.5);
            else
                plot(smoothedPSTH, 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1.5);  % Default: Gray
            end

            % Add metadata to the plot
            title(sprintf('Unit: %s', unitID), 'Interpreter', 'none');
            xlabel('Time (ms)');
            ylabel('Firing Rate (Hz)');
            hold off;
        end
    end
end
