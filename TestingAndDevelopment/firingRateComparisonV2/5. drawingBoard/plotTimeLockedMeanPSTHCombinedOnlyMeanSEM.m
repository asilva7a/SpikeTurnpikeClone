function plotAllMeanPTSHs = plotTimeLockedMeanPSTHCombinedOnlyMeanSEM(cellDataStruct, figureFolder, treatmentTime)
    % plotTimeLockedMeanPSTHCombinedOnlyMeanSEM: Generates a single figure with three subplots of time-locked mean PSTHs.
    % Each subplot shows either responsive, non-responsive, or all units combined with only the mean and SEM.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - figureFolder: Directory where the plots will be saved.
    %   - treatmentTime: Time (in seconds) where treatment was administered (for time-locking).

    if nargin < 3
        treatmentTime = 1860; % Default treatment time in seconds
    end

    % Define colors for each response type and mean PSTH
    colors = struct('Responsive', [1, 0, 0], ...   % Red for responsive units
                    'NonResponsive', [0, 0, 1], ... % Blue for non-responsive units
                    'Mean', [0, 0, 0]);             % Black for mean PSTH

    % Loop through each group and recording
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            recordingData = cellDataStruct.(groupName).(recordingName).recordingData;

            % Initialize arrays for collecting PSTHs by response type
            responsivePSTHs = [];
            nonResponsivePSTHs = [];
            timeVector = []; % Initialize in case it needs to be set from data

            % Collect PSTHs based on response type
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
                    if strcmp(unitData.responseType, 'Increased') || strcmp(unitData.responseType, 'Decreased')
                        responsivePSTHs = [responsivePSTHs; psth];
                    else
                        nonResponsivePSTHs = [nonResponsivePSTHs; psth];
                    end
                end
            end

            % Create a figure with three subplots
            figure('Position', [100, 100, 1400, 800]);

            % Plot 1: Responsive Units
            subplot(3, 1, 1);
            if ~isempty(responsivePSTHs)
                meanResponsivePSTH = mean(responsivePSTHs, 1, 'omitnan');
                semResponsivePSTH = std(responsivePSTHs, 0, 1, 'omitnan') / sqrt(size(responsivePSTHs, 1));
                plotPSTHMeanSEM(timeVector, meanResponsivePSTH, semResponsivePSTH, ...
                    colors.Responsive, colors.Mean, ...
                    sprintf('%s - %s - Responsive Units', groupName, recordingName), treatmentTime);
            end

            % Plot 2: Non-Responsive Units
            subplot(3, 1, 2);
            if ~isempty(nonResponsivePSTHs)
                meanNonResponsivePSTH = mean(nonResponsivePSTHs, 1, 'omitnan');
                semNonResponsivePSTH = std(nonResponsivePSTHs, 0, 1, 'omitnan') / sqrt(size(nonResponsivePSTHs, 1));
                plotPSTHMeanSEM(timeVector, meanNonResponsivePSTH, semNonResponsivePSTH, ...
                    colors.NonResponsive, colors.Mean, ...
                    sprintf('%s - %s - Non-Responsive Units', groupName, recordingName), treatmentTime);
            end

            % Plot 3: All Units Combined
            subplot(3, 1, 3);
            allPSTHs = [responsivePSTHs; nonResponsivePSTHs];
            if ~isempty(allPSTHs)
                meanAllPSTH = mean(allPSTHs, 1, 'omitnan');
                semAllPSTH = std(allPSTHs, 0, 1, 'omitnan') / sqrt(size(allPSTHs, 1));
                plotPSTHMeanSEM(timeVector, meanAllPSTH, semAllPSTH, ...
                    colors.Mean, colors.Mean, ...
                    sprintf('%s - %s - All Units Combined', groupName, recordingName), treatmentTime);
            end

            % Save figure
            saveDir = fullfile(figureFolder, 'CombinedPlots');
            if ~isfolder(saveDir)
                mkdir(saveDir);
            end
            fileName = sprintf('%s_%s_CombinedPSTH_MeanSEM.png', groupName, recordingName);
            saveas(gcf, fullfile(saveDir, fileName));
            fprintf('Figure saved to: %s\n', fullfile(saveDir, fileName));

            close(gcf); % Close to free memory
        end
    end
end

%% Helper Function: Plot Mean PSTH with SEM (no individual traces)
function plotPSTHMeanSEM(timeVector, meanPSTH, semPSTH, lineColor, avgColor, plotTitle, treatmentTime)
    % plotPSTHMeanSEM: Helper function to plot mean PSTH with SEM as a shaded area (no individual traces).
    %
    % Inputs:
    %   - timeVector: Vector of time points for the PSTH
    %   - meanPSTH, semPSTH: Mean and SEM of the PSTH
    %   - lineColor: Color for the SEM shading
    %   - avgColor: Color for the mean PSTH line
    %   - plotTitle: Title for the subplot
    %   - treatmentTime: Time in seconds for the vertical line

    hold on;

    % Plot SEM as a shaded area
    fill([timeVector, fliplr(timeVector)], ...
         [meanPSTH + semPSTH, fliplr(meanPSTH - semPSTH)], ...
         lineColor, 'FaceAlpha', 0.3, 'EdgeColor', 'none');

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
