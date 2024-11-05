function plotGroupAveragePSTHWithResponse(cellDataStruct, figureFolder)
    % Define color mapping for each response type
    colorMap = containers.Map({'Increased', 'Decreased', 'No Change'}, ...
                              {[1, 0, 0, 0.3], [0, 0, 1, 0.3], [0.5, 0.5, 0.5, 0.3]});

    % Loop through each group to accumulate and plot PSTH data
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        % Initialize variables for accumulating PSTH data across the group
        allGroupPSTHs = [];
        timeVector = [];

        % Loop through each recording within the group to gather PSTHs
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            % Check if there are any units in the recording
            if isempty(units)
                warning('No units found in recording %s of group %s. Skipping...', recordingName, groupName);
                continue;
            end
            
            % Ensure the first unit has the 'psthSmoothed' field for consistency
            firstUnit = units{1};
            if ~isfield(cellDataStruct.(groupName).(recordingName).(firstUnit), 'psthSmoothed')
                warning('Field `psthSmoothed` is missing in unit %s of recording %s. Skipping...', firstUnit, recordingName);
                continue;
            end
            
            psthLength = length(cellDataStruct.(groupName).(recordingName).(firstUnit).psthSmoothed);
            fprintf('Processing recording %s in group %s with PSTH length %d\n', recordingName, groupName, psthLength);

            % Initialize a figure for the group plot
            figure;
            hold on;
            
            % Accumulate individual PSTHs for each unit within the recording
            unitCount = 0;
            
            for u = 1:numel(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Ensure data is available
                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                    psth = unitData.psthSmoothed;
                    binWidth = unitData.binWidth;
                    binEdges = unitData.binEdges;
                    timeVector = binEdges(1:end-1) + binWidth / 2;

                    % Preallocate `allGroupPSTHs` array if empty
                    if isempty(allGroupPSTHs)
                        allGroupPSTHs = NaN(0, psthLength);
                    end

                    % Check if the psth length matches expected length
                    if length(psth) == psthLength
                        allGroupPSTHs = [allGroupPSTHs; psth];
                        unitCount = unitCount + 1;
                        fprintf('  Plotting Unit: %s in Recording: %s, Group: %s\n', unitID, recordingName, groupName); % Debug statement for unit plotting
                    else
                        warning('PSTH length mismatch for Unit %s. Skipping this unit.', unitID);
                        continue;
                    end

                    % Set color based on response type
                    responseType = unitData.responseType;
                    if isKey(colorMap, responseType)
                        colorVal = colorMap(responseType);
                        lineColor = colorVal(1:3);
                        alphaVal = colorVal(4);
                        plot(timeVector, psth, 'Color', [lineColor, alphaVal], 'LineWidth', 0.5);
                    end
                else
                    warning('Missing required fields in Unit %s of Recording %s. Skipping...', unitID, recordingName);
                end
            end

            fprintf('Group %s, Recording %s: %d units plotted.\n', groupName, recordingName, unitCount);

            % Calculate and plot the group-averaged PSTH across all units
            avgPSTH = mean(allGroupPSTHs, 1, 'omitnan');
            fill([timeVector, fliplr(timeVector)], [avgPSTH, zeros(size(avgPSTH))], ...
                'k', 'FaceAlpha', 0.5, 'EdgeColor', 'none');

            xlabel('Time (s)');
            ylabel('Firing Rate (spikes/s)');
            title(sprintf('Group Average Smoothed PSTH with Individual Responses\n%s', groupName));
            legend([plot(NaN, NaN, 'k-', 'LineWidth', 2), ...
                    plot(NaN, NaN, '-', 'Color', [1, 0, 0, 0.3]), ...
                    plot(NaN, NaN, '-', 'Color', [0, 0, 1, 0.3]), ...
                    plot(NaN, NaN, '-', 'Color', [0.5, 0.5, 0.5, 0.3])], ...
                   {'Average PSTH', 'Increased', 'Decreased', 'No Change'}, ...
                   'Location', 'Best');
            hold off;

            saveDir = fullfile(figureFolder, groupName, 'Group PSTHs');
            if ~isfolder(saveDir)
                mkdir(saveDir);
                fprintf('Created directory: %s\n', saveDir);
            end

            timestamp = datestr(now, 'yyyy-mm-dd_HH-MM');
            fileName = sprintf('GroupAveragePSTH_%s_%s.png', groupName, timestamp);
            saveas(gcf, fullfile(saveDir, fileName));
            fprintf('Figure saved to: %s\n', fullfile(saveDir, fileName));

            close(gcf);
        end
    end
end



