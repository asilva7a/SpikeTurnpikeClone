function plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, treatmentTime)
    % plotTimeLockedMeanPSTHCombined: Generates a single figure with three subplots of time-locked mean PSTHs.
    % Each subplot shows either responsive, non-responsive, or all units combined.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - figureFolder: Directory where the plots will be saved.
    %   - treatmentTime: Time (in seconds) where treatment was administered (for time-locking).

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

            % Create a figure with three subplots
            figure('Position', [100, 100, 1400, 800]);

            % Plot 1: Responsive Units (Increased and Decreased)
            subplot(3, 1, 1);
            responsivePSTHs = [increasedPSTHs; decreasedPSTHs];
            if ~isempty(responsivePSTHs)
                meanResponsivePSTH = mean(responsivePSTHs, 1, 'omitnan');
                semResponsivePSTH = std(responsivePSTHs, 0, 1, 'omitnan') / sqrt(size(responsivePSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanResponsivePSTH, semResponsivePSTH, ...
                    increasedPSTHs, decreasedPSTHs, colors, colors.Mean, ...
                    sprintf('%s - %s - Responsive Units', groupName, recordingName), treatmentTime);
            end

            % Plot 2: Non-Responsive Units (No Change)
            subplot(3, 1, 2);
            if ~isempty(noChangePSTHs)
                meanNoChangePSTH = mean(noChangePSTHs, 1, 'omitnan');
                semNoChangePSTH = std(noChangePSTHs, 0, 1, 'omitnan') / sqrt(size(noChangePSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanNoChangePSTH, semNoChangePSTH, ...
                    noChangePSTHs, [], colors, colors.Mean, ...
                    sprintf('%s - %s - Non-Responsive Units', groupName, recordingName), treatmentTime);
            end

            % Plot 3: All Units Combined
            subplot(3, 1, 3);
            allPSTHs = [increasedPSTHs; decreasedPSTHs; noChangePSTHs];
            if ~isempty(allPSTHs)
                meanAllPSTH = mean(allPSTHs, 1, 'omitnan');
                semAllPSTH = std(allPSTHs, 0, 1, 'omitnan') / sqrt(size(allPSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanAllPSTH, semAllPSTH, ...
                    increasedPSTHs, decreasedPSTHs, colors, colors.Mean, ...
                    sprintf('%s - %s - All Units Combined', groupName, recordingName), treatmentTime);
            end

            % Save figure
            saveDir = fullfile(figureFolder, 'CombinedPlots');
            if ~isfolder(saveDir)
                mkdir(saveDir);
            end
            fileName = sprintf('%s_%s_CombinedPSTH.png', groupName, recordingName);
            saveas(gcf, fullfile(saveDir, fileName));
            fprintf('Figure saved to: %s\n', fullfile(saveDir, fileName));

            close(gcf); % Close to free memory
        end
    end
end

%% Helper Function: Plot PSTH with Overlay in a Subplot
function plotPSTHWithOverlaySubplot(timeVector, meanPSTH, semPSTH, increasedPSTHs, decreasedPSTHs, colors, avgColor, plotTitle, treatmentTime)
    % plotPSTHWithOverlaySubplot: Helper function to plot mean PSTH with SEM and overlay individual traces in a subplot.
    %
    % Inputs:
    %   - timeVector: Vector of time points for the PSTH
    %   - meanPSTH, semPSTH: Mean and SEM of the PSTH
    %   - increasedPSTHs, decreasedPSTHs: Matrices of individual PSTHs for responsive units
    %   - colors: Struct with colors for Increased, Decreased, No Change, and Mean
    %   - avgColor: Color for the mean PSTH line
    %   - plotTitle: Title for the subplot
    %   - treatmentTime: Time in seconds for the vertical line

    hold on;

    % Plot individual PSTHs with color and transparency for each type
    for i = 1:size(increasedPSTHs, 1)
        plot(timeVector, increasedPSTHs(i, :), 'Color', colors.Increased(1:3), 'LineWidth', 0.5, 'Color', [colors.Increased(1:3), colors.Increased(4)]);
    end
    for i = 1:size(decreasedPSTHs, 1)
        plot(timeVector, decreasedPSTHs(i, :), 'Color', colors.Decreased(1:3), 'LineWidth', 0.5, 'Color', [colors.Decreased(1:3), colors.Decreased(4)]);
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
    xlim([timeVector(1), timeVector(end)]);

    hold off;
end
