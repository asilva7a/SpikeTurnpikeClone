function plotGroupAveragePSTHWithResponse(cellDataStruct, figureFolder)
    % plotGroupAveragePSTHWithResponse: Generates plots of group-averaged smoothed PSTHs with individual units.
    % Inputs:
    %   - cellDataStruct: Data structure containing all group, recording, and unit data.
    %   - figureFolder: Root folder where figures will be saved.

    % Define color mapping for each response type with higher opacity
    colorMap = containers.Map({'Increased', 'Decreased', 'No Change'}, ...
                              {[1, 0, 0, 0.6], [0, 0, 1, 0.6], [0.5, 0.5, 0.5, 0.6]});

    % Set treatment time and x-axis limit
    treatmentTime = 1860;
    xLimit = 5400;

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
            
            % Retrieve length of PSTH from the first unit for preallocation
            firstUnit = units{1};
            psthLength = length(cellDataStruct.(groupName).(recordingName).(firstUnit).psthSmoothed);

            % Initialize a figure for the group plot
            figure;
            hold on;
            
            % Accumulate individual PSTHs for each unit within the recording
            unitCount = 0;  % Counter to confirm the number of units processed
            
            for u = 1:numel(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Ensure data is available
                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                    psth = unitData.psthSmoothed;
                    binWidth = unitData.binWidth;
                    binEdges = unitData.binEdges;
                    timeVector = binEdges(1:end-1) + binWidth / 2; % Use bin centers for plotting

                    % Preallocate `allGroupPSTHs` array if empty
                    if isempty(allGroupPSTHs)
                        allGroupPSTHs = NaN(0, psthLength);
                    end

                    % Check if the psth length matches expected length
                    if length(psth) == psthLength
                        allGroupPSTHs = [allGroupPSTHs; psth];  % Accumulate PSTH data across group
                        unitCount = unitCount + 1;
                    else
                        warning('PSTH length mismatch for Unit %s. Skipping this unit.', unitID);
                        continue;
                    end

                    % Set color based on response type
                    responseType = unitData.responseType;
                    if isKey(colorMap, responseType)
                        colorVal = colorMap(responseType);
                        lineColor = colorVal(1:3);  % Extract RGB
                        alphaVal = colorVal(4);     % Set higher alpha for more opacity
                        
                        % Plot each PSTH line with increased opacity
                        plot(timeVector, psth, 'Color', [lineColor, alphaVal], 'LineWidth', 0.8);
                    end
                end
            end

            % Debug statement to verify the number of units plotted
            fprintf('Group %s, Recording %s: %d units plotted.\n', groupName, recordingName, unitCount);

            % Calculate and plot the group-averaged PSTH across all units
            avgPSTH = mean(allGroupPSTHs, 1, 'omitnan');
            stdPSTH = std(allGroupPSTHs, [], 1, 'omitnan');  % Calculate std for error bands
            
            % Plot the average PSTH on top with a thick black line
            plot(timeVector, avgPSTH, 'k', 'LineWidth', 2.5, 'DisplayName', 'Average PSTH');

            % Plot error band (1 standard deviation)
            fill([timeVector, fliplr(timeVector)], [avgPSTH + stdPSTH, fliplr(avgPSTH - stdPSTH)], ...
                'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

            % Add treatment line in green
            xline(treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5, 'DisplayName', 'Treatment Time');
            xlim([0, xLimit]); % Set x-axis limit

            % Add labels, title, and legend
            xlabel('Time (s)');
            ylabel('Firing Rate (spikes/s)');
            title(sprintf('Group Average Smoothed PSTH with Individual Responses\n%s', groupName));
            legend([plot(NaN, NaN, 'k-', 'LineWidth', 2.5), ...
                    plot(NaN, NaN, '-', 'Color', [1, 0, 0, 0.6]), ...
                    plot(NaN, NaN, '-', 'Color', [0, 0, 1, 0.6]), ...
                    plot(NaN, NaN, '-', 'Color', [0.5, 0.5, 0.5, 0.6]), ...
                    plot(NaN, NaN, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5)], ...
                   {'Average PSTH', 'Increased', 'Decreased', 'No Change', 'Treatment Time'}, ...
                   'Location', 'Best');

            hold off;

            % Define save path for group-level figure
            saveDir = fullfile(figureFolder, groupName, 'Group PSTHs');
            if ~isfolder(saveDir)
                mkdir(saveDir);
                fprintf('Created directory: %s\n', saveDir);
            end

            % Save figure
            timestamp = datestr(now, 'yyyy-mm-dd_HH-MM');
            fileName = sprintf('GroupAveragePSTH_%s_%s.png', groupName, timestamp);
            saveas(gcf, fullfile(saveDir, fileName));
            fprintf('Figure saved to: %s\n', fullfile(saveDir, fileName));

            close(gcf);  % Close the figure to free up memory
        end
    end
end