function generate_PSTH(all_data, binSize, smoothingWindow, moment, prePeriod, postPeriod, responseTypeVec, unitIDs)
    % Define colors for responsivity types
    colors = struct('Increased', [1, 0, 0], ...  % Red
                    'Decreased', [0, 0, 1], ...  % Blue
                    'NoChange', [0, 0, 0]);      % Black

    % Get group names from the data
    groupNames = fieldnames(all_data);

    % Iterate over each recording group (e.g., EMX, PVALB)
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        % Create a new figure for the current group
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');

        % Initialize a subplot index
        subplotIdx = 1;

        % Iterate over recordings within the current group
        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            unitNames = fieldnames(all_data.(groupName).(recordingName));

            % Iterate over units within the recording
            for u = 1:length(unitNames)
                unitName = unitNames{u};
                unitData = all_data.(groupName).(recordingName).(unitName);
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                % Calculate the PSTH for this unit
                psthCounts = histcounts(spikeTimes, ...
                    moment - prePeriod : binSize : moment + postPeriod);
                smoothedPSTH = conv(psthCounts, smoothingWindow, 'same');

                % Determine the response type for the current unit
                unitIndex = find(strcmpi(unitIDs, unitName), 1);
                if isempty(unitIndex)
                    warning('Unit %s not found in unitIDs. Skipping.', unitName);
                    continue;
                end
                responseType = responseTypeVec{unitIndex};

                % Select the color based on the response type
                switch responseType
                    case 'Increased'
                        color = colors.Increased;
                    case 'Decreased'
                        color = colors.Decreased;
                    otherwise
                        color = colors.NoChange;
                end

                % Create a subplot for the current unit
                subplot(length(recordingNames), ceil(length(unitNames) / length(recordingNames)), subplotIdx);
                hold on;

                % Plot the PSTH
                plot(smoothedPSTH, 'Color', color, 'LineWidth', 1.5);
                title(['Unit: ', unitName]);
                xlabel('Time Bin');
                ylabel('Firing Rate (Hz)');

                % Update subplot index
                subplotIdx = subplotIdx + 1;
            end
        end
    end
end
