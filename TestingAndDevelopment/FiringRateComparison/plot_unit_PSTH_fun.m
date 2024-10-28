function plot_unit_PSTH_fun(responsive_units_struct, params, savePath)
    % Default save path if not provided
    if nargin < 3
        savePath = pwd;
    end

    groupNames = fieldnames(responsive_units_struct);  % Get all groups

    % Iterate over groups
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(responsive_units_struct.(groupName));

        % Iterate over recordings within the group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(responsive_units_struct.(groupName).(recordingName));

            % Iterate over each unit in the recording
            for u = 1:length(units)
                unitID = units{u};
                unitData = responsive_units_struct.(groupName).(recordingName).(unitID);

                disp(['Plotting PSTH for ', groupName, ' - ', recordingName, ' - ', unitID]);  % Debug

                % Extract PSTH data
                psth = unitData.PSTH;
                if isempty(psth)
                    warning('    PSTH for unit %s is empty. Skipping plot.', unitID);
                    continue;
                end

                % Create figure
                figure('Name', ['PSTH - ', groupName, ' - ', unitID], 'NumberTitle', 'off');
                hold on;

                % Plot PSTH
                plot(1:length(psth), psth, 'LineWidth', 1.5);
                xline(params.moment, '--k', 'LineWidth', 1.5);  % Dashed line for moment

                % Add labels and save plot
                title(sprintf('PSTH for %s (Response: %s)', unitID, unitData.ResponseType));
                xlabel('Time Bins');
                ylabel('Firing Rate (Hz)');
                saveas(gcf, fullfile(savePath, sprintf('PSTH_%s_%s.png', groupName, unitID)));
                hold off;
                close(gcf);
            end
        end
    end
end
