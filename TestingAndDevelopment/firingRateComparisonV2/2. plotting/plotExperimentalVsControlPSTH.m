function plotExperimentalVsControlPSTH(cellDataStruct, figureFolder)
    % plotExperimentalVsControlPSTH: Generates plots comparing smoothed PSTHs of experimental
    % groups (Emx, Pvalb) vs. Control group.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing all recording and unit data.
    %   - figureFolder: Root folder for saving figures.

    % Define group identifiers for filtering
    groupKeywords = {'Emx', 'Pvalb', 'Control'};
    colorMap = containers.Map({'Increased', 'Decreased', 'No Change'}, ...
                              {[1, 0, 0, 0.3], [0, 0, 1, 0.3], [0.5, 0.5, 0.5, 0.3]}); % RGBA format with transparency

    % Initialize a figure with subplots for each group comparison
    figure;
    numGroups = numel(groupKeywords);

    for g = 1:numGroups
        groupName = groupKeywords{g};

        % Initialize variables for accumulating PSTH data across the group
        allGroupPSTHs = [];
        timeVector = [];

        % Loop through each recording within the cellDataStruct
        recordings = fieldnames(cellDataStruct);
        for r = 1:length(recordings)
            recordingName = recordings{r};

            % Only include recordings that match the group keyword
            if contains(recordingName, groupName, 'IgnoreCase', true)
                units = fieldnames(cellDataStruct.(recordingName));

                % Retrieve length of PSTH from the first unit for preallocation
                firstUnit = units{1};
                psthLength = length(cellDataStruct.(recordingName).(firstUnit).psthSmoothed);

                % Accumulate individual PSTHs for each unit within the recording
                groupPSTHs = NaN(numel(units), psthLength);
                unitCount = 0;  % Counter for valid units

                for u = 1:numel(units)
                    unitID = units{u};
                    unitData = cellDataStruct.(recordingName).(unitID);

                    % Ensure necessary fields are available
                    if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                        psth = unitData.psthSmoothed;
                        binWidth = unitData.binWidth;
                        binEdges = unitData.binEdges;
                        timeVector = binEdges(1:end-1) + binWidth / 2; % Bin centers

                        % Accumulate PSTH data if lengths match
                        if length(psth) == psthLength
                            groupPSTHs(unitCount + 1, :) = psth;
                            unitCount = unitCount + 1;

                            % Plot individual PSTH with color based on response type
                            responseType = unitData.responseType;
                            if isKey(colorMap, responseType)
                                colorVal = colorMap(responseType);
                                lineColor = colorVal(1:3);  % RGB
                                alphaVal = colorVal(4);     % Transparency
                                
                                subplot(1, numGroups, g);
                                hold on;
                                plot(timeVector, psth, 'Color', [lineColor, alphaVal], 'LineWidth', 0.5);
                            end
                        else
                            warning('PSTH length mismatch for Unit %s. Skipping this unit.', unitID);
                        end
                    end
                end

                % Accumulate across group if data was collected for this recording
                allGroupPSTHs = [allGroupPSTHs; groupPSTHs(1:unitCount, :)];
            end
        end

        % Plot the group-averaged PSTH if data was collected
        if ~isempty(allGroupPSTHs)
            avgPSTH = mean(allGroupPSTHs, 1, 'omitnan');

            % Plot the average PSTH with transparency
            subplot(1, numGroups, g);
            fill([timeVector, fliplr(timeVector)], [avgPSTH, zeros(size(avgPSTH))], ...
                'k', 'FaceAlpha', 0.5, 'EdgeColor', 'none');

            % Set plot details
            xlabel('Time (s)');
            ylabel('Firing Rate (spikes/s)');
            title(sprintf('Average Smoothed PSTH\n%s', groupName));
            legend([plot(NaN, NaN, 'k-', 'LineWidth', 2), ...
                    plot(NaN, NaN, '-', 'Color', [1, 0, 0, 0.3]), ...
                    plot(NaN, NaN, '-', 'Color', [0, 0, 1, 0.3]), ...
                    plot(NaN, NaN, '-', 'Color', [0.5, 0.5, 0.5, 0.3])], ...
                   {'Average PSTH', 'Increased', 'Decreased', 'No Change'}, ...
                   'Location', 'Best');
            hold off;
        else
            subplot(1, numGroups, g);
            text(0.5, 0.5, 'No data available', 'HorizontalAlignment', 'center');
            title(sprintf('%s Group', groupName));
        end
    end

    % Define save path for the figure
    saveDir = fullfile(figureFolder, 'Experimental_vs_Control');
    if ~isfolder(saveDir)
        mkdir(saveDir);
        fprintf('Created directory: %s\n', saveDir);
    end

    % Save figure with timestamp
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM');
    fileName = sprintf('Experimental_vs_Control_%s.png', timestamp);
    saveas(gcf, fullfile(saveDir, fileName));
    fprintf('Figure saved to: %s\n', fullfile(saveDir, fileName));

    close(gcf);  % Close the figure to free memory
end
