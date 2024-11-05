function plotPSTHLines(cellDataStruct, treatmentTime, figureFolder)
    % plotPSTHLines: Plots raw and smoothed PSTHs with a user-defined treatment line.
    %
    % Inputs:
    %   - cellDataStruct: Structure containing PSTH data.
    %   - treatmentTime: Time (in seconds) where the treatment was administered.
    %   - figureFolder: Base folder where figures will be saved.
    %
    % Note: Saves each figure in a "Line PSTHs" subfolder within each recording directory.

    % Set Default Argument for treatmentTime
    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 1860;
        fprintf('No treatment period specified. Defaulting to 1860s.\n');
    end

    if nargin < 3 || isempty(figureFolder)
        error('Figure folder path is required. Please provide a valid folder path.');
    end

    % Loop over each group, recording, and unit in the structure
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            % Define the directory for "Line PSTHs" within each group and recording
            saveDir = fullfile(figureFolder, groupName, recordingName, 'Line PSTHs');
            if ~isfolder(saveDir)
                mkdir(saveDir);
                fprintf('Created directory for Line PSTHs: %s\n', saveDir);
            end

            for u = 1:length(units)
                unitID = units{u};

                % Extract bin edges and PSTH data for this unit
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                binEdges = unitData.binEdges;
                rawPSTH = unitData.psthRaw;
                smoothedPSTH = unitData.psthSmoothed;

                % Validate data existence
                if isempty(binEdges) || isempty(rawPSTH) || isempty(smoothedPSTH)
                    warning('Skipping Unit %s: Missing data for raw or smoothed PSTH.\n', unitID);
                    continue;
                end

                % Calculate bin centers
                binCenters = binEdges(1:end-1) + diff(binEdges) / 2;

                % Prepare metadata and file name
                metadataText = generateMetadataText(unitData, unitID);
                figTitle = sprintf('PSTH Lines: %s - %s - %s', groupName, recordingName, unitID);
                timestamp = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss');
                fileName = sprintf('LinePSTH-%s_%s.png', unitID, char(timestamp));
                fullPath = fullfile(saveDir, fileName);

                % Call the helper function to create and save the figure
                createStyledPSTHFigure(binCenters, rawPSTH, smoothedPSTH, treatmentTime, figTitle, fullPath, metadataText);
                fprintf('Successfully saved: %s\n', fullPath);
            end
        end
    end
end

%% Helper Function: Generate Metadata Text for a Unit
function metadataText = generateMetadataText(unitData, unitID)
    % Generate a formatted string with metadata for the given unit.

    cellType = unitData.CellType;
    templateChannel = unitData.TemplateChannel;

    % Determine Single Unit Status
    singleUnitStatus = "Not Single Unit";
    if unitData.IsSingleUnit == 1
        singleUnitStatus = "Single Unit";
    end

    % Format the metadata text
    metadataText = sprintf('Cell Type: %s | Channel: %d | %s | Unit ID: %s', ...
                           cellType, templateChannel, singleUnitStatus, unitID);
end

%% Helper Function: Create and Style PSTH Figure
function createStyledPSTHFigure(binCenters, rawPSTH, smoothedPSTH, treatmentTime, figTitle, fullPath, metadataText)
    % createStyledPSTHFigure: Creates, styles, and saves a PSTH figure with enhanced quality.

    % Create a new figure with improved quality settings
    f = figure('Visible', 'off');  % Set 'Visible' to 'off' for faster processing
    hold on;

    % Plot raw and smoothed PSTH lines
    plot(binCenters, rawPSTH, '-k', 'LineWidth', 1.5, 'DisplayName', 'Raw PSTH');
    plot(binCenters, smoothedPSTH, '-r', 'LineWidth', 2, 'DisplayName', 'Smoothed PSTH');

    % Add a vertical line at the treatment time
    xline(treatmentTime, '--b', 'LineWidth', 2, 'DisplayName', 'Treatment');

    % Add labels, title, and legend
    xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Firing Rate (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
    title(figTitle, 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best');

    % Ensure that rawPSTH and smoothedPSTH contain valid data for y-axis limits
    maxRaw = max(rawPSTH(~isnan(rawPSTH)));  % Ignore NaNs in max calculation
    maxSmooth = max(smoothedPSTH(~isnan(smoothedPSTH)));
    maxY = max([maxRaw, maxSmooth]);

    % Set y-axis limits if maxY is valid
    if isempty(maxY) || isnan(maxY) || maxY <= 0
        warning('No valid data in rawPSTH or smoothedPSTH. Setting y-axis limits to [0, 1].');
        ylim([0, 1]);
    else
        ylim([0, maxY * 1.1]);  % Scale up by 10% for readability
    end

    % Set axis limits and aesthetics
    xlim([min(binCenters), max(binCenters)]);
    set(gca, 'Box', 'off', 'TickDir', 'out', 'FontSize', 10, 'LineWidth', 1.2);

    % Add metadata at the bottom of the figure
    annotation('textbox', [0.1, 0.02, 0.8, 0.05], ...
               'String', metadataText, 'EdgeColor', 'none', ...
               'HorizontalAlignment', 'center', 'FontSize', 10, 'Interpreter', 'none');

    % Save the figure with high resolution
    exportgraphics(f, fullPath, 'Resolution', 300);
    close(f);  % Close the figure to free up memory
end
