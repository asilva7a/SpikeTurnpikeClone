function plot_unit_PSTH_fun(psthData, moment, savePath)
    % Plot individual PSTHs for each group and unit, color-coded by response type,
    % and save each plot with a dashed line indicating the moment.

    if nargin < 3
        savePath = pwd;  % Default to current directory if savePath is not provided
    end

    groups = fieldnames(psthData);  % Extract all groups from psthData

    for g = 1:length(groups)
        groupName = groups{g};  % Current group name
        units = fieldnames(psthData.(groupName));  % Extract units for this group

        for u = 1:length(units)
            unitName = units{u};  % Current unit name
            unitData = psthData.(groupName).(unitName);

            % Extract PSTH and response type
            psth = unitData.PSTH;
            responseType = unitData.ResponseType;

            % Create a figure for this unit
            figure('Name', ['PSTH - ', groupName, ' - ', unitName], 'NumberTitle', 'off');
            hold on;

            % Plot the PSTH for this unit
            timeBins = linspace(0, length(psth) - 1, length(psth));  % Assuming time bins are consecutive
            plot(timeBins, psth, 'Color', getColorForResponseType(responseType), 'LineWidth', 1.5);

            % Add vertical dashed line at the moment (e.g., stimulus onset)
            xline(moment, '--k', 'LineWidth', 1.5);  % Dashed black line

            % Add title, labels, and legend
            title(sprintf('PSTH for %s (Response: %s)', unitName, responseType));
            xlabel('Time Bins');
            ylabel('Firing Rate (Hz)');
            legend({sprintf('%s PSTH', unitName), 'Moment'}, 'Location', 'best');

            % Save the figure as a PNG file
            saveas(gcf, fullfile(savePath, sprintf('PSTH_%s_%s.png', groupName, unitName)));

            hold off;
            close(gcf);  % Close the figure after saving
        end
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


