function plotAveragePSTHWithResponse(cellDataStruct, figureFolder)
    % plotAveragePSTHWithResponse: Generates plots of average smoothed PSTHs with individual units.
    % Inputs:
    %   - cellDataStruct: Data structure containing all group, recording, and unit data.
    %   - figureFolder: Root folder where figures will be saved.

    % Define color mapping for each response type
    colorMap = containers.Map({'Increased', 'Decreased', 'No Change'}, ...
                              {[1, 0, 0, 0.3], [0, 0, 1, 0.3], [0.5, 0.5, 0.5, 0.3]}); % RGBA format with transparency

    % Loop through groups and recordings
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            numUnits = numel(units);  % Number of units for preallocation
            
            % Retrieve length of PSTH from the first unit for preallocation
            firstUnit = units{1};
            psthLength = length(cellDataStruct.(groupName).(recordingName).(firstUnit).psthSmoothed);

            % Preallocate array for all PSTHs
            allPSTHs = NaN(numUnits, psthLength);  

            % Prepare figure
            figure;
            hold on;

            % Create dummy plots for each response type to include in the legend
            legendHandles = [];
            legendLabels = {'Increased', 'Decreased', 'No Change'};
            for k = 1:numel(legendLabels)
                responseType = legendLabels{k};
                colorVal = colorMap(responseType);  % Get RGBA color
                lineColor = colorVal(1:3);          % Extract RGB
                alphaVal = colorVal(4);             % Extract alpha (transparency)

                % Plot dummy line with specified color and transparency
                h = plot(NaN, NaN, '-', 'Color', [lineColor, alphaVal], 'LineWidth', 1.5);
                legendHandles = [legendHandles, h]; %#ok<AGROW>
            end

            % Plot individual unit PSTHs with transparency based on response type
            for u = 1:numUnits
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Check if psthSmoothed and responseType are available
                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                    psth = unitData.psthSmoothed;
                    binWidth = unitData.binWidth;
                    binEdges = unitData.binEdges;
                    timeVector = binEdges(1:end-1) + binWidth / 2; % Use bin centers for plotting

                    % Store PSTH for averaging if size matches
                    if length(psth) == psthLength
                        allPSTHs(u, :) = psth;
                    else
                        warning('PSTH length mismatch for Unit %s. Skipping this unit.', unitID);
                        continue;
                    end

                    % Set color based on response type; skip if responseType is unknown
                    responseType = unitData.responseType;
                    if isKey(colorMap, responseType)
                        colorVal = colorMap(responseType);  % Retrieve RGBA value from color map
                        lineColor = colorVal(1:3);          % Extract RGB
                        alphaVal = colorVal(4);             % Extract alpha (transparency)

                        % Plot individual PSTH with transparency
                        plot(timeVector, psth, 'Color', [lineColor, alphaVal], 'LineWidth', 0.5);
                    else
                        % Skip plotting if the response type is not recognized
                        fprintf('Unknown response type for Unit %s. Skipping plot.\n', unitID);
                        continue;
                    end
                end
            end

            % Calculate and plot the average PSTH across units
            avgPSTH = mean(allPSTHs, 1, 'omitnan');  % Calculate average ignoring NaNs
            plot(timeVector, avgPSTH, 'k-', 'LineWidth', 2); % Plot with solid black line

            % Add labels, title, and legend
            xlabel('Time (s)');
            ylabel('Firing Rate (spikes/s)');
            title(sprintf('Average Smoothed PSTH with Individual Responses\n%s - %s', groupName, recordingName));
            legend([plot(NaN, NaN, 'k-', 'LineWidth', 2), legendHandles], ...
                   {'Average PSTH', 'Increased', 'Decreased', 'No Change'}, ...
                   'Location', 'Best');

            % Define save path following the directory structure
            saveDir = fullfile(figureFolder, groupName, recordingName, 'Smoothed PSTHs');
            if ~isfolder(saveDir)
                mkdir(saveDir);
                fprintf('Created directory: %s\n', saveDir);
            end
            
            % Save the figure
            timestamp = datestr(now, 'yyyy-mm-dd_HH-MM');
            fileName = sprintf('AveragePSTH_%s_%s.png', recordingName, timestamp);
            saveas(gcf, fullfile(saveDir, fileName));
            fprintf('Figure saved to: %s\n', fullfile(saveDir, fileName));

            hold off;
            close(gcf); % Close the figure to free up memory
        end
    end
end



