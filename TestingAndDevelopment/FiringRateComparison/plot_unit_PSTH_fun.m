function plot_unit_PSTH_fun(responsive_units_struct, params, savePath)
    % Plot individual PSTHs for each group, recording, and unit.
    % Uses the params struct for moment and other settings.

    if nargin < 3
        savePath = pwd;  % Default to current directory if savePath is not provided
    end

    % Extract the analysis parameters from the params struct
    moment = params.moment;

    % Get the group names from the responsive_units_struct
    groups = fieldnames(responsive_units_struct);

    % Iterate over each group
    for g = 1:length(groups)
        groupName = groups{g};
        recordings = fieldnames(responsive_units_struct.(groupName));

        % Iterate over each recording within the group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(responsive_units_struct.(groupName).(recordingName));

            % Iterate over each unit within the recording
            for u = 1:length(units)
                unitName = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitName);

                % Extract PSTH and response type
                psth = unitData.PSTH;
                responseType = unitData.ResponseType;

                % Create a figure for this unit
                figure('Name', ['PSTH - ', groupName, ' - ', recordingName, ' - ', unitName], ...
                    'NumberTitle', 'off');
                hold on;

                % Generate the time bins for plotting
                timeBins = linspace(0, length(psth) - 1, length(psth));

                % Plot the PSTH for this unit
                plot(timeBins, psth, 'Color', getColorForResponseType(responseType), 'LineWidth', 1.5);

                % Add vertical dashed line at the moment (e.g., stimulus onset)
                xline(moment, '--k', 'LineWidth', 1.5);  % Dashed black line

                % Add title, labels, and legend
                title(sprintf('PSTH for %s (Response: %s)', unitName, responseType), 'Interpreter', 'none');
                xlabel('Time Bins');
                ylabel('Firing Rate (Hz)');
                legend({sprintf('%s PSTH', unitName), 'Moment'}, 'Location', 'best');

                % Save the figure as a PNG file
                saveName = sprintf('PSTH_%s_%s_%s.png', groupName, recordingName, unitName);
                saveas(gcf, fullfile(savePath, saveName));

                hold off;
                close(gcf);  % Close the figure after saving
            end
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
