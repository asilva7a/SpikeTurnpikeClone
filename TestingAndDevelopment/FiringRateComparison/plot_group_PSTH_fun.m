function plot_group_PSTH(psthData, smoothingWindow)
    % Plot time-locked PSTHs for each unit with metadata
    
    % Define a common time vector (adjust as needed)
    time_vector = linspace(-1000, 2000, size(psthData.(1).PSTH, 2)); % Example: 3000 ms range

    % Iterate over each group in the data
    groupNames = fieldnames(psthData);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        units = fieldnames(psthData.(groupName));

        % Create a figure for this group
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');

        % Plot each unit individually as a sanity check
        for u = 1:length(units)
            unitID = units{u};
            unitData = psthData.(groupName).(unitID);

            % Apply light smoothing to the PSTH
            smoothedPSTH = conv(unitData.PSTH, smoothingWindow, 'same');

            % Create a subplot for this unit
            subplot(ceil(length(units)/5), 5, u); % Adjust the grid for all units
            plot(time_vector, smoothedPSTH, 'LineWidth', 1.5);

            % Add title and labels with unit metadata
            title(sprintf('Unit: %s | Type: %s\nRec: %s | Channel: %d\nResp: %s', ...
                unitID, unitData.CellType, unitData.RecordingName, unitData.Channel, unitData.ResponseType));
            xlabel('Time (ms)');
            ylabel('Firing Rate (Hz)');

            % Ensure the plot layout is clean
            axis tight;
        end

        % Adjust figure layout to avoid overlap
        sgtitle(['PSTHs for Group: ', groupName]);
    end
end
