function plotAllRawPSTHs(cellDataStruct, lineTime, figureFolder)
    % plotAllRawPSTHs: Plots and saves PSTHs for all units with metadata.
    %
    % Inputs:
    %   - cellDataStruct: Struct containing the PSTH data.
    %   - lineTime: Time (in seconds) to draw a vertical line (optional).
    %   - figureFolder: Folder where the figures will be saved.

    %% Set Default Arguments
    if nargin < 2 || isempty(lineTime)
        lineTime = 1860;  % Default treatment moment
        fprintf('No treatment period specified. Defaulting to 1860s.\n');
    end

    if nargin < 2 && isempty(figureFolder)
        error('Figure folder path is required. Please provide a valid folder path.');
    end

    % Define "Raw PSTHs" subdirectory path within the provided figure folder
    rawPSTHFolder = fullfile(figureFolder, 'Raw PSTHs');

    % Ensure the "Raw PSTHs" folder exists
    if ~isfolder(rawPSTHFolder)
        mkdir(rawPSTHFolder);
        fprintf('Created "Raw PSTHs" folder: %s\n', rawPSTHFolder);
    end

    % Initialize counters to track results
    totalUnits = 0;
    successCount = 0;
    errorCount = 0;

    %% Start Figure Plotting Loop
    % Loop over all groups, recordings, and units
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            % Create a group/recording-specific subfolder inside the figure folder
            saveDir = fullfile(figureFolder, groupName, recordingName);
            if ~isfolder(saveDir)
                mkdir(saveDir);
                fprintf('Created directory: %s\n', saveDir);
            end

            % Process each unit
            for u = 1:length(units)
                unitID = units{u};
                totalUnits = totalUnits + 1;

                fprintf('Processing: Group: %s | Recording: %s | Unit: %s\n', ...
                        groupName, recordingName, unitID);

                try
                    % Extract data and validate required fields
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    binEdges = unitData.binEdges;
                    fullPSTH = unitData.psthRaw;

                    if isempty(binEdges) || isempty(fullPSTH)
                        warning('Skipping Unit %s: Missing PSTH or bin edges.\n', unitID);
                        continue;
                    end

                    % Prepare metadata for the plot
                    metadataText = generateMetadataText(unitData, unitID);

                    % Generate plot title
                    figTitle = sprintf('PSTH: %s - %s - %s', groupName, recordingName, unitID);
                    timestamp = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss');

                    % Generate save path
                    fileName = sprintf('RawPSTH-%s_%s.png', unitID, char(timestamp));
                    fullPath = fullfile(saveDir, fileName);

                    % Plot and save the PSTH with metadata
                    plotAndSavePSTH(binEdges, fullPSTH, lineTime, figTitle, fullPath, metadataText);
                    fprintf('Successfully saved: %s\n', fullPath);
                    successCount = successCount + 1;

                catch ME
                    % Handle errors gracefully and continue processing
                    errorCount = errorCount + 1;
                    warning('Error processing Unit %s: %s\n', unitID, ME.message);
                end
            end
        end
    end

    % Display a summary of results
    fprintf('\nProcessing completed.\n');
    fprintf('Total Units Processed: %d\n', totalUnits);
    fprintf('Successfully Processed: %d\n', successCount);
    fprintf('Errors Encountered: %d\n', errorCount);
end

%% Helper Function: Plot and Save a Single PSTH with Metadata
function plotAndSavePSTH(binEdges, fullPSTH, lineTime, figTitle, fullPath, metadataText)
    % Create a new figure
    f = figure;
    ax = axes('Parent', f);

    % Plot the PSTH as black bars
    bar(ax,binEdges(1:end-1), fullPSTH, 'FaceColor', 'k', 'EdgeColor', 'k');

    % Add labels and title
    xlabel('Time (s)');
    ylabel('Firing Rate (spikes/s)');
    title(figTitle);
    
    % Adjust bottom margin to make space for metadata
    ax.Position(2) = ax.Position(2) + 0.05;  % Shift axis upwards slightly
    ax.Position(4) = ax.Position(4) - 0.05;  % Adjust height to fit

    % Add a vertical line at the treatment moment, if provided
    if ~isempty(lineTime)
        hold on;
        xline(lineTime, 'r--', 'LineWidth', 2);  % Red dashed line
    end

    % Add metadata annotation at the bottom of the plot
    annotation('textbox', [0.1, 0.02, 0.8, 0.05], ... % Adjusted position
               'String', metadataText, ...
               'EdgeColor', 'none', ...
               'HorizontalAlignment', 'center', ...
               'FontSize', 10, ...
               'Interpreter', 'none');

    % Improve plot appearance
    grid off;
    set(gca, 'Box', 'off', 'TickDir', 'out');

    % Save the figure as a PNG with high resolution
    exportgraphics(f, fullPath, 'Resolution', 300);

    % Close the figure to free memory
    close(f);
end

%% Helper Function: Generate Metadata Text for a Unit
function metadataText = generateMetadataText(unitData, unitID)
    % Generate a formatted string with metadata for the given unit.

    cellType = unitData.CellType;
    templateChannel = unitData.TemplateChannel;

    % Determine Single Unit Status
    if unitData.IsSingleUnit == 1
        singleUnitStatus = "Single Unit";
    else
        singleUnitStatus = "Not Single Unit";
    end

    % Format the metadata text
    metadataText = sprintf('Cell Type: %s | Channel: %d | %s | Unit ID: %s', ...
                           cellType, templateChannel, singleUnitStatus, unitID);
end


