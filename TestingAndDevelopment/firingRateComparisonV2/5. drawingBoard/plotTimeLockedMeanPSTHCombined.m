function plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, treatmentTime)
    % plotTimeLockedMeanPSTHCombined: Generates a single figure with three subplots of time-locked mean PSTHs.
    % Each subplot shows positively modulated, negatively modulated, or unresponsive units.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - figureFolder: Directory where the plots will be saved.
    %   - treatmentTime: Time (in seconds) where treatment was administered (for time-locking).

    % Debugging input
    % Load the data, can be omitted for full deploy
    files = {'cellDataStruct.mat', 'cellDataStructPath.mat', 'dataFilePath.mat', ...
             'dataFolder.mat', 'figureFolder.mat'};
    for i = 1:length(files)
        load(fullfile('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables', files{i}));
    end

    % Default args
    if nargin < 3
        treatmentTime = 1860; % Default treatment time in seconds
    end

    % Define colors for each response type and mean PSTH
    colors = struct('Increased', [1, 0, 0, 0.3], ...   % Red with transparency
                    'Decreased', [0, 0, 1, 0.3], ...   % Blue with transparency
                    'NoChange', [0.5, 0.5, 0.5, 0.3], ... % Grey with transparency
                    'Mean', [0, 0, 0]);                % Black for mean PSTH

    % Loop through each group and recording
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            recordingData = cellDataStruct.(groupName).(recordingName).recordingData;

            % Initialize arrays for collecting PSTHs by response type
            increasedPSTHs = [];
            decreasedPSTHs = [];
            noChangePSTHs = [];
            timeVector = []; % Initialize in case it needs to be set from data

            % Collect individual PSTHs from units based on response type
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                    psth = unitData.psthSmoothed;
                    binWidth = unitData.binWidth;
                    binEdges = unitData.binEdges;
                    timeVector = binEdges(1:end-1) + binWidth / 2; % Bin centers

                    % Separate by response type
                    switch unitData.responseType
                        case 'Increased'
                            increasedPSTHs = [increasedPSTHs; psth];
                        case 'Decreased'
                            decreasedPSTHs = [decreasedPSTHs; psth];
                        case 'No Change'
                            noChangePSTHs = [noChangePSTHs; psth];
                    end
                end
            end

            % Create a figure with three subplots arranged in a 1x3 layout
            figure('Position', [100, 100, 1600, 500]);

            % Plot 1: Positively Modulated Units (Increased)
            subplot(1, 3, 1);
            if ~isempty(increasedPSTHs)
                meanIncreasedPSTH = mean(increasedPSTHs, 1, 'omitnan');
                semIncreasedPSTH = std(increasedPSTHs, 0, 1, 'omitnan') / sqrt(size(increasedPSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanIncreasedPSTH, semIncreasedPSTH, ...
                    increasedPSTHs, [], colors.Increased, colors.Mean, ...
                    sprintf('%s - %s - Positively Modulated Units', groupName, recordingName), treatmentTime);
            else
                title(sprintf('%s - %s - Positively Modulated Units (No Data)', groupName, recordingName));
            end

            % Plot 2: Negatively Modulated Units (Decreased)
            subplot(1, 3, 2);
            if ~isempty(decreasedPSTHs)
                meanDecreasedPSTH = mean(decreasedPSTHs, 1, 'omitnan');
                semDecreasedPSTH = std(decreasedPSTHs, 0, 1, 'omitnan') / sqrt(size(decreasedPSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanDecreasedPSTH, semDecreasedPSTH, ...
                    decreasedPSTHs, [], colors.Decreased, colors.Mean, ...
                    sprintf('%s - %s - Negatively Modulated Units', groupName, recordingName), treatmentTime);
            else
                title(sprintf('%s - %s - Negatively Modulated Units (No Data)', groupName, recordingName));
            end

            % Plot 3: Non-Responsive Units (No Change)
            subplot(1, 3, 3);
            if ~isempty(noChangePSTHs)
                meanNoChangePSTH = mean(noChangePSTHs, 1, 'omitnan');
                semNoChangePSTH = std(noChangePSTHs, 0, 1, 'omitnan') / sqrt(size(noChangePSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanNoChangePSTH, semNoChangePSTH, ...
                    noChangePSTHs, [], colors.NoChange, colors.Mean, ...
                    sprintf('%s - %s - Non-Responsive Units', groupName, recordingName), treatmentTime);
            else
                title(sprintf('%s - %s - Non-Responsive Units (No Data)', groupName, recordingName));
            end

            % Save figure
            saveDir = fullfile(figureFolder, 'ModulatedPlots');
            if ~isfolder(saveDir)
                mkdir(saveDir);
            end
            fileName = sprintf('%s_%s_ModulatedPSTH.png', groupName, recordingName);
            saveas(gcf, fullfile(saveDir, fileName));
            fprintf('Figure saved to: %s\n', fullfile(saveDir, fileName));

            close(gcf); % Close to free memory
        end
    end
end

%% Helper Function: Plot PSTH with Overlay in a Subplot
function plotPSTHWithOverlaySubplot(timeVector, meanPSTH, semPSTH, individualPSTHs, ~, color, avgColor, plotTitle, treatmentTime)
    % plotPSTHWithOverlaySubplot: Helper function to plot mean PSTH with SEM and overlay individual traces in a subplot.
    %
    % Inputs:
    %   - timeVector: Vector of time points for the PSTH
    %   - meanPSTH, semPSTH: Mean and SEM of the PSTH
    %   - individualPSTHs: Matrix of individual PSTHs for the current response type
    %   - color: Color for individual traces
    %   - avgColor: Color for the mean PSTH line
    %   - plotTitle: Title for the subplot
    %   - treatmentTime: Time in seconds for the vertical line

    hold on;

    % Plot individual PSTHs with color and transparency for each type
    for i = 1:size(individualPSTHs, 1)
        plot(timeVector, individualPSTHs(i, :), 'Color', [color(1:3), color(4)], 'LineWidth', 0.5);
    end

    % Plot mean PSTH with SEM as a shaded area
    fill([timeVector, fliplr(timeVector)], ...
         [meanPSTH + semPSTH, fliplr(meanPSTH - semPSTH)], ...
         avgColor, 'FaceAlpha', 0.3, 'EdgeColor', 'none');

    % Plot mean PSTH line on top
    plot(timeVector, meanPSTH, 'Color', avgColor, 'LineWidth', 2);

    % Plot treatment line
    xline(treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5);

    % Labels, title, and limits
    xlabel('Time (s)');
    ylabel('Firing Rate (spikes/s)');
    title(plotTitle);

    % Set axis limits
    ylim([0 inf]);  % Start y-axis at 0 and let it auto-adjust
    xlim([0 5400]); % Set x-axis limit to maximum time

    hold off;
end

