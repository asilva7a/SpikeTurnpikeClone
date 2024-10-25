function generate_unit_PSTHs(all_data, binSize, smoothingWindow, moment, prePeriod, postPeriod, responseTypeVec, unitIDs)
    % Define colors for responsivity types
    colors = struct('Increased', [1, 0, 0], ...  % Red
                    'Decreased', [0, 0, 1], ...  % Blue
                    'NoChange', [0, 0, 0]);      % Black

    % Iterate over all recording groups
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        % Create a new figure for the current group
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');

        % Create three subplots: one for each response type
        responseTypes = {'Increased', 'Decreased', 'No Change'};
        for rt = 1:length(responseTypes)
            subplot(1, 3, rt);  % 3 subplots: one per response type
            hold on;
            title([groupName, ' - ', responseTypes{rt}]);
            xlabel('Time Bin');
            ylabel('Firing Rate (Hz)');

            % Iterate over recordings within the current group
            for r = 1:length(recordingNames)
                recordingName = recordingNames{r};
                unitNames = fieldnames(all_data.(groupName).(recordingName));

                % Iterate over units within the current recording
                for u = 1:length(unitNames)
                    unitName = strtrim(unitNames{u});
                    unitData = all_data.(groupName).(recordingName).(unitName);

                    % Calculate PSTH for this unit
                    spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;
                    psthCounts = histcounts(spikeTimes, ...
                        moment - prePeriod : binSize : moment + postPeriod);
                    smoothedPSTH = conv(psthCounts, smoothingWindow, 'same');

                    % Find the response type for the unit
                    unitIndex = find(strcmpi(unitIDs, unitName), 1);
                    if isempty(unitIndex)
                        warning('Unit %s not found in unitIDs. Skipping.', unitName);
                        continue;
                    end
                    responseType = responseTypeVec{unitIndex};

                    % Only plot if the response type matches the current subplot
                    if strcmpi(responseType, responseTypes{rt})
                        plot(smoothedPSTH, 'Color', colors.(strrep(responseType, ' ', '')), 'LineWidth', 1.5);
                    end
                end
            end

            hold off;
        end
    end
end
