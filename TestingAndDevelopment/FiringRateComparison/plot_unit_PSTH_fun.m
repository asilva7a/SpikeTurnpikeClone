function plot_unit_PSTH_fun(psthData)
    % Plot individual PSTHs for each group and unit, color-coded by response type.
    
    groups = fieldnames(psthData);  % Extract all groups from psthData

    for g = 1:length(groups)
        groupName = groups{g};  % Current group name
        units = fieldnames(psthData.(groupName));  % Extract units for this group

        % Create a figure for this group
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');
        hold on;

        for u = 1:length(units)
            unitName = units{u};  % Current unit name
            unitData = psthData.(groupName).(unitName);

            % Extract PSTH and response type
            psth = unitData.PSTH;
            responseType = unitData.ResponseType;

            % Define plot color based on response type
            color = getColorForResponseType(responseType);

            % Plot the PSTH for this unit
            plot(psth, 'Color', color, 'LineWidth', 1.5);

            % Add a legend entry for this unit
            legendInfo{u} = sprintf('%s - %s', unitName, responseType);
        end

        % Customize plot appearance
        title(['PSTHs for ', groupName]);
        xlabel('Time Bins');
        ylabel('Firing Rate (Hz)');
        legend(legendInfo, 'Location', 'best');
        hold off;
    end
end

% Helper function to define color based on response type
function color = getColorForResponseType(responseType)
    switch responseType
        case 'Increased'
            color = [1, 0, 0];  % Red
        case 'Decreased'
            color = [0, 0, 1];  % Blue
        otherwise
            color = [0, 0, 0];  % Black
    end
end

