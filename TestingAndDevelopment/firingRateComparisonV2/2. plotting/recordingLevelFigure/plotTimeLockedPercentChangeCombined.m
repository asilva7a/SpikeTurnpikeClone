function plotTimeLockedPercentChangeCombined(cellDataStruct, figureFolder, treatmentTime, plotType, unitFilter, outlierFilter)
    % plotTimeLockedPercentChangeCombined: Generates a single figure with three subplots of time-locked percent change PSTHs.
    % Each subplot shows positively modulated, negatively modulated, or unresponsive units.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - figureFolder: Directory where the plots will be saved.
    %   - treatmentTime: Time (in seconds) where treatment was administered (for time-locking).
    %   - plotType: Type of plot ('mean+sem' or 'mean+individual')
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').
    %   - outlierFilter: If true, excludes units marked as outliers (isOutlierExperimental == 1).

    % Set default values if not provided
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
            saveDir = fullfile(figureFolder, groupName, recordingName,'0. recordingFigures'); % Saves figure at recording level
            if ~isfolder(saveDir)
                mkdir(saveDir);
                fprintf('Created directory for %s percent change PSTHs: %s\n',recordingName, saveDir);
            end

            % Initialize arrays for collecting percent changes by response type
            increasedPercentChange = [];
            decreasedPercentChange = [];
            noChangePercentChange = [];
            timeVector = []; % Initialize in case it needs to be set from data

            % Collect individual percent changes from units based on response type
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Display the unit being processed for debugging
                fprintf('Processing Group: %s | Recording: %s | Unit: %s\n', ...
                        groupName, recordingName, unitID);

                % Apply outlier filter: skip unit if marked as an outlier
                if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental == 1
                    fprintf('Skipping outlier unit %s from group %s, recording %s\n', unitID, groupName, recordingName);
                    continue; % Skip this unit
                end

                % Apply unit filter based on IsSingleUnit field
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if (strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                   (strcmp(unitFilter, 'multi') && isSingleUnit)
                    continue; % Skip unit if it doesn't match the filter
                end

                % Proceed if unit has required percent change data and response type
                if isfield(unitData, 'psthPercentChange') && isfield(unitData, 'responseType')
                    psthPercentChange = unitData.psthPercentChange;

                    if any(isnan(psthPercentChange)) || any(isinf(psthPercentChange))
                        fprintf('NaN or Inf values detected in psthPercentChange for unit %s from group %s, recording %s\n', unitID, groupName, recordingName);
                        disp('Pausing execution. Press any key to continue...');
                        pause;
                        fprintf('Skipping unit %s from group %s, recording %s due to NaN or Inf values in psthPercentChange\n', unitID, groupName, recordingName);
                        continue; % Skip this unit
                    end

                    % Extract bin information
                    binWidth = unitData.binWidth;
                    binEdges = unitData.binEdges;
                    timeVector = binEdges(1:end-1) + binWidth / 2; % Bin centers

                    % Separate by response type
                    switch unitData.responseType
                        case 'Increased'
                            increasedPercentChange = [increasedPercentChange; psthPercentChange];
                        case 'Decreased'
                            decreasedPercentChange = [decreasedPercentChange; psthPercentChange];
                        case 'No Change'
                            noChangePercentChange = [noChangePercentChange; psthPercentChange];
                    end
                end
            end

            % Create a figure with three subplots arranged in a 1x3 layout
            figure('Position', [100, 100, 1600, 500]);
            
            % Add the main title with group, recording names, and unit filter type
            sgtitle(sprintf('%s - %s - %s (%s units)', groupName, recordingName, plotType, unitFilter));

            % Plot 1: Positively Modulated Units (Increased)
            subplot(1, 3, 1);
            if ~isempty(increasedPercentChange)
                meanIncreasedPercentChange = mean(increasedPercentChange, 1, 'omitnan');
                semIncreasedPercentChange = std(increasedPercentChange, 0, 1, 'omitnan') / sqrt(size(increasedPercentChange, 1));
                plotPercentChangeWithOverlay(timeVector, meanIncreasedPercentChange, semIncreasedPercentChange, ...
                    increasedPercentChange, colors.Increased, 'Increased', treatmentTime, plotType);
            else
                title('Increased (No Data)');
            end

            % Plot 2: Negatively Modulated Units (Decreased)
            subplot(1, 3, 2);
            if ~isempty(decreasedPercentChange)
                meanDecreasedPercentChange = mean(decreasedPercentChange, 1, 'omitnan');
                semDecreasedPercentChange = std(decreasedPercentChange, 0, 1, 'omitnan') / sqrt(size(decreasedPercentChange, 1));
                plotPercentChangeWithOverlay(timeVector, meanDecreasedPercentChange, semDecreasedPercentChange, ...
                    decreasedPercentChange, colors.Decreased, 'Decreased', treatmentTime, plotType);
            else
                title('Decreased (No Data)');
            end

            % Plot 3: Non-Responsive Units (No Change)
            subplot(1, 3, 3);
            if ~isempty(noChangePercentChange)
                meanNoChangePercentChange = mean(noChangePercentChange, 1, 'omitnan');
                semNoChangePercentChange = std(noChangePercentChange, 0, 1, 'omitnan') / sqrt(size(noChangePercentChange, 1));
                plotPercentChangeWithOverlay(timeVector, meanNoChangePercentChange, semNoChangePercentChange, ...
                    noChangePercentChange, colors.NoChange, 'No Change', treatmentTime, plotType);
            else
                title('No Change (No Data)');
            end

            % Main Saving Block
            try
                timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
                fileName = sprintf('%s_%s_%s_timeLockedPercentChangeCombined_%s.fig', ...
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

%% Helper Function: Plot Percent Change PSTH with Overlay in a Subplot using shadedErrorBar or individual traces
function plotPercentChangeWithOverlay(timeVector, meanPercentChange, semPercentChange, individualPercentChanges, color, plotTitle, treatmentTime, plotType)
    % plotPercentChangeWithOverlay: Helper function to plot mean percent change PSTH with SEM or individual traces.
    %
    % Inputs:
    %   - timeVector: Vector of time points for the PSTH
    %   - meanPercentChange, semPercentChange: Mean and SEM of the percent change
    %   - individualPercentChanges: Matrix of individual percent change traces for the current response type
    %   - color: Color for both individual traces and mean percent change line
    %   - plotTitle: Title for the subplot
    %   - treatmentTime: Time in seconds for the vertical line
    %   - plotType: Type of plot ('mean+sem' or 'mean+individual')

    hold on;

    if strcmp(plotType, 'mean+sem')
        % Plot mean percent change with SEM using shadedErrorBar, using the color of the response type
        shadedErrorBar(timeVector, meanPercentChange, semPercentChange, 'lineprops', {'Color', color(1:3), 'LineWidth', 2});
    elseif strcmp(plotType, 'mean+individual')
        % Plot individual percent change traces with color and transparency
        for i = 1:size(individualPercentChanges, 1)
            plot(timeVector, individualPercentChanges(i, :), 'Color', [color(1:3), color(4)], 'LineWidth', 0.5);
        end
        % Plot mean percent change on top with the same color as individual traces
        plot(timeVector, meanPercentChange, 'Color', color(1:3), 'LineWidth', 2);
    else
        error("plotType must be either 'mean+sem' or 'mean+individual'");
    end

    % Plot treatment line
    xline(treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5);

    % Labels, title, and limits
    xlabel('Time (s)');
    ylabel('Percent Change from Baseline (%)');
    title(plotTitle);

    % Set axis limits
    ylim([-100, max(meanPercentChange + semPercentChange) * 1.5]); % Adjust y-axis to fit data
    xlim([timeVector(1), timeVector(end)]);

    hold off;
end
