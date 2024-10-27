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
        unitIDs = fieldnames(units);   % Get unit IDs within the group

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

            % Filter and plot units of the current response type
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
                    % Smooth the PSTH data
                    smoothedPSTH = conv(unitData.PSTH, smoothingWindow, 'same');
                    
                    % Plot the PSTH with the appropriate color
                    plot(smoothedPSTH, 'Color', colors.(responseType), 'LineWidth', 1.5);

                    % Optionally, add unit ID as text on the plot (for clarity)
                    text(length(smoothedPSTH), smoothedPSTH(end), unitID, ...
                         'FontSize', 8, 'Interpreter', 'none');
                end
            end
            hold off;
        end
    end
end

