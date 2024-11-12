function plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, treatmentTime, plotType, unitFilter, outlierFilter)
    % plotTimeLockedMeanPSTHCombined: Generates a single figure with three subplots of time-locked mean PSTHs.
    % Each subplot shows positively modulated, negatively modulated, or unresponsive units.
    % Plot-Level: Recording
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - figureFolder: Directory where the plots will be saved.
    %   - treatmentTime: Time (in seconds) where treatment was administered (for time-locking).
    %   - plotType: Type of plot ('mean+sem' or 'mean+individual')
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').
    %   - outlierFilter: If true, excludes units marked as outliers (isOutlierExperimental == 1).

    % Set default for plotType and unitFilter if not provided
    if nargin < 6 || isempty(outlierFilter)
        outlierFilter = true; % Default to excluding outliers
    end
    if nargin < 5
        unitFilter = 'both'; % Default to including both unit types
    end
    if nargin < 4
        plotType = 'mean+sem'; % Default to mean + SEM
    end
    if nargin < 3
        treatmentTime = 1860; % Default treatment time in seconds
    end

    % Define colors for each response type
    colors = struct('Increased', [1, 0, 0, 0.3], ...   % Red with transparency
                    'Decreased', [0, 0, 1, 0.3], ...   % Blue with transparency
                    'NoChange', [0.5, 0.5, 0.5, 0.3]); % Grey with transparency

    % Loop through each group and recording
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            
            % Define the directory for figures within each group and recording
            saveDir = fullfile(figureFolder, groupName, recordingName);
            if ~isfolder(saveDir)
                mkdir(saveDir);
                fprintf('Created directory for %s combined PSTHs: %s\n',recordingName, saveDir);
            end

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

                % Apply outlier filter: skip unit if marked as an outlier
                if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental == 1
                    continue; % Skip this unit
                end

                % Apply unit filter based on IsSingleUnit field
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if (strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                   (strcmp(unitFilter, 'multi') && isSingleUnit)
                    continue; % Skip unit if it doesn't match the filter
                end

                % Proceed if unit has required fields
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
                        otherwise
                            warning('Unknown response type: %s', unitData.responseType);
                            continue;
                    end
                end
            end

            % Create a figure with three subplots arranged in a 1x3 layout
            figure('Position', [100, 100, 1600, 500]);
            
            % Add the main title with group, recording names, and unit filter type
            sgtitle(sprintf('%s - %s - %s (%s units)', groupName, recordingName, plotType, unitFilter));

            % Plot 1: Positively Modulated Units (Increased)
            subplot(1, 3, 1);
            if ~isempty(increasedPSTHs)
                meanIncreasedPSTH = mean(increasedPSTHs, 1, 'omitnan');
                semIncreasedPSTH = std(increasedPSTHs, 0, 1, 'omitnan') / sqrt(size(increasedPSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanIncreasedPSTH, semIncreasedPSTH, ...
                    increasedPSTHs, colors.Increased, 'Increased', treatmentTime, plotType);
            else
                title('Increased (No Data)');
            end

            % Plot 2: Negatively Modulated Units (Decreased)
            subplot(1, 3, 2);
            if ~isempty(decreasedPSTHs)
                meanDecreasedPSTH = mean(decreasedPSTHs, 1, 'omitnan');
                semDecreasedPSTH = std(decreasedPSTHs, 0, 1, 'omitnan') / sqrt(size(decreasedPSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanDecreasedPSTH, semDecreasedPSTH, ...
                    decreasedPSTHs, colors.Decreased, 'Decreased', treatmentTime, plotType);
            else
                title('Decreased (No Data)');
            end

            % Plot 3: Non-Responsive Units (No Change)
            subplot(1, 3, 3);
            if ~isempty(noChangePSTHs)
                meanNoChangePSTH = mean(noChangePSTHs, 1, 'omitnan');
                semNoChangePSTH = std(noChangePSTHs, 0, 1, 'omitnan') / sqrt(size(noChangePSTHs, 1));
                plotPSTHWithOverlaySubplot(timeVector, meanNoChangePSTH, semNoChangePSTH, ...
                    noChangePSTHs, colors.NoChange, 'No Change', treatmentTime, plotType);
            else
                title('No Change (No Data)');
            end

            % Main Saving Block
            try
                timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
                fileName = sprintf('%s_%s_%s_recordingSmoothedPSTH_%s.fig', ...
                    groupName, recordingName, plotType, timeStamp);
                    
                % Call the save function
                savingFunction(gcf, saveDir, fileName);
                
            catch ME
                fprintf('Critical error in figure saving:\n');
                fprintf('Message: %s\n', ME.message);
                fprintf('Stack:\n');
                for k = 1:length(ME.stack)
                    fprintf('File: %s, Line: %d, Function: %s\n', ...
                        ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
                end
            end
        end
    end
end


%% Helper Function: Plot PSTH with Overlay in a Subplot using shadedErrorBar or individual traces
function plotPSTHWithOverlaySubplot(timeVector, meanPSTH, semPSTH, individualPSTHs, color, plotTitle, treatmentTime, plotType)
    % plotPSTHWithOverlaySubplot: Helper function to plot mean PSTH with SEM or individual traces.
    %
    % Inputs:
    %   - timeVector: Vector of time points for the PSTH
    %   - meanPSTH, semPSTH: Mean and SEM of the PSTH
    %   - individualPSTHs: Matrix of individual PSTHs for the current response type
    %   - color: Color for both individual traces and mean PSTH line
    %   - plotTitle: Title for the subplot
    %   - treatmentTime: Time in seconds for the vertical line
    %   - plotType: Type of plot ('mean+sem' or 'mean+individual')

    hold on;

    if strcmp(plotType, 'mean+sem')
        % Plot mean PSTH with SEM using shadedErrorBar, using the color of the response type
        shadedErrorBar(timeVector, meanPSTH, semPSTH, 'lineprops', {'Color', color(1:3), 'LineWidth', 2});
    elseif strcmp(plotType, 'mean+individual')
        % Plot individual PSTHs with color and transparency
        for i = 1:size(individualPSTHs, 1)
            plot(timeVector, individualPSTHs(i, :), 'Color', [color(1:3), color(4)], 'LineWidth', 0.5);
        end
        % Plot mean PSTH on top with the same color as individual traces
        plot(timeVector, meanPSTH, 'Color', color(1:3), 'LineWidth', 2);
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
