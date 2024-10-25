function generate_unit_PSTHs(all_data, binSize, smoothingWindow, moment, preTreatmentPeriod, postTreatmentPeriod, responseTypeVec, unitIDs)
    % Define colors for responsivity types
    colors = struct('Increased', [1, 0, 0], ...  % Red
                    'Decreased', [0, 0, 1], ...  % Blue
                    'NoChange', [0, 0, 0]);      % Black

    % Iterate over groups in the data
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        % Create a new figure for the current group
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');
        subplotIdx = 1;  % Subplot index

        % Iterate over recordings
        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            unitNames = fieldnames(all_data.(groupName).(recordingName));

            % Iterate over units
            for u = 1:length(unitNames)
                unitName = strtrim(unitNames{u});  % Trim spaces
                unitData = all_data.(groupName).(recordingName).(unitName);

                % Calculate PSTH
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;
                psthCounts = histcounts(spikeTimes, ...
                    moment - preTreatmentPeriod : binSize : moment + postTreatmentPeriod);
                smoothedPSTH = conv(psthCounts, smoothingWindow, 'same');

                % Find the unit's response type from the data table
                unitIndex = find(strcmpi(unitIDs, unitName), 1);
                if isempty(unitIndex)
                    warning('Unit %s not found in unitIDs. Skipping.', unitName);
                    continue;
                end
                responseType = responseTypeVec{unitIndex};

                % Choose color based on response type
                switch responseType
                    case 'Increased'
                        color = colors.Increased;
                    case 'Decreased'
                        color = colors.Decreased;
                    otherwise
                        color = colors.NoChange;
                end

                % Create subplot and plot the PSTH
                subplot(length(recordingNames), ceil(length(unitNames) / length(recordingNames)), subplotIdx);
                hold on;
                plot(smoothedPSTH, 'Color', color, 'LineWidth', 1.5);
                title(['Unit: ', unitName]);
                xlabel('Time Bin');
                ylabel('Firing Rate (Hz)');
                hold off;

                % Update subplot index
                subplotIdx = subplotIdx + 1;
            end
        end
    end
end
