function plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, treatmentTime, plotType)
    % plotTimeLockedMeanPSTHCombined: Generates a single figure with three subplots of time-locked mean PSTHs.
    % Each subplot shows positively modulated, negatively modulated, or unresponsive units.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - figureFolder: Directory where the plots will be saved.
    %   - treatmentTime: Time (in seconds) where treatment was administered (for time-locking).
    %   - plotType: Type of plot ('mean+sem' or 'mean+individual')

    % Set default for plotType if not provided
    if nargin < 4
        plotType = 'mean+sem'; % Default to mean + SEM
    end
    
    % Default treatment time if not provided
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
            
            % Add the main title with group and recording names
            sgtitle(sprintf('%s - %s', groupName, recordingName));

            % Plot 1: Positively Modulated Units (Increased)
            subplot(1, 3, 1);
            if ~isempty(increasedPSTHs)
                meanIncreasedPSTH = mean(increasedPSTHs, 1, 'omitnan');
                semIncreasedPSTH = std(increasedPSTHs, 0, 1, 'omitnan') / sqrt(size(increasedPSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanIncreasedPSTH, semIncreasedPSTH, ...
                    increasedPSTHs, colors.Increased, colors.Mean, 'Increased', treatmentTime, plotType);
            else
                title('Increased (No Data)');
            end

            % Plot 2: Negatively Modulated Units (Decreased)
            subplot(1, 3, 2);
            if ~isempty(decreasedPSTHs)
                meanDecreasedPSTH = mean(decreasedPSTHs, 1, 'omitnan');
                semDecreasedPSTH = std(decreasedPSTHs, 0, 1, 'omitnan') / sqrt(size(decreasedPSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanDecreasedPSTH, semDecreasedPSTH, ...
                    decreasedPSTHs, colors.Decreased, colors.Mean, 'Decreased', treatmentTime, plotType);
            else
                title('Decreased (No Data)');
            end

            % Plot 3: Non-Responsive Units (No Change)
            subplot(1, 3, 3);
            if ~isempty(noChangePSTHs)
                meanNoChangePSTH = mean(noChangePSTHs, 1, 'omitnan');
                semNoChangePSTH = std(noChangePSTHs, 0, 1, 'omitnan') / sqrt(size(noChangePSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanNoChangePSTH, semNoChangePSTH, ...
                    noChangePSTHs, colors.NoChange, colors.Mean, 'No Change', treatmentTime, plotType);
            else
                title('No Change (No Data)');
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

%% Helper Function: Plot PSTH with Overlay in a Subplot using shadedErrorBar or individual traces
function plotPSTHWithOverlaySubplot(timeVector, meanPSTH, semPSTH, individualPSTHs, color, avgColor, plotTitle, treatmentTime, plotType)
    % plotPSTHWithOverlaySubplot: Helper function to plot mean PSTH with SEM or individual traces.
    %
    % Inputs:
    %   - timeVector: Vector of time points for the PSTH
    %   - meanPSTH, semPSTH: Mean and SEM of the PSTH
    %   - individualPSTHs: Matrix of individual PSTHs for the current response type
    %   - color: Color for individual traces
    %   - avgColor: Color for the mean PSTH line
    %   - plotTitle: Title for the subplot
    %   - treatmentTime: Time in seconds for the vertical line
    %   - plotType: Type of plot ('mean+sem' or 'mean+individual')

    hold on;

    if strcmp(plotType, 'mean+sem')
        % Plot mean PSTH with SEM using shadedErrorBar
        shadedErrorBar(timeVector, meanPSTH, semPSTH, 'lineprops', {'Color', avgColor, 'LineWidth', 2});
    elseif strcmp(plotType, 'mean+individual')
        % Plot individual PSTHs with color and transparency
        for i = 1:size(individualPSTHs, 1)
            plot(timeVector, individualPSTHs(i, :), 'Color', [color(1:3), color(4)], 'LineWidth', 0.5);
        end
        % Plot mean PSTH on top
        plot(timeVector, meanPSTH, 'Color', avgColor, 'LineWidth', 2);
    else
        error("plotType must be either 'mean+sem' or 'mean+individual'");
    end

    % Plot treatment line
    xline(treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5);

    % Labels, title, and limits
    xlabel('Time (s)');
    ylabel('Firing Rate (spikes/s)');
    title(plotTitle);
    
    % Set axis limits
    ylim([0 inf]);  % Set y-axis lower limit to 0 and let the upper limit auto-adjust
    xlim([0 5400]); % Set x-axis upper limit to 5400 seconds

    hold off;
end




