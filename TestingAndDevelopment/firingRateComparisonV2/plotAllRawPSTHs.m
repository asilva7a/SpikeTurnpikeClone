function plotAllRawPSTHs(cellDataStruct, lineTime)
    % plotAllRawPSTHs: Plots and saves PSTHs for all units with metadata.
    
    %% Set Default Arg values
    if nargin < 2 || isempty(lineTime)
        lineTime = 1860;
        fprintf('No treatment period specified. Defaulting to 1860s.\n');
    end

    % Set up the base save directory for figures
    baseDir = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestFigures';

    if ~isfolder(baseDir)
        mkdir(baseDir);  % Create the directory if it doesn't exist
        fprintf('Created new directory: %s\n', baseDir);
    end

    % Initialize counters for tracking processing results
    totalUnits = 0;
    successCount = 0;
    errorCount = 0;

    % Loop through all groups, recordings, and units
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            % Create the group/recording-specific save directory
            saveDir = fullfile(baseDir, groupName, recordingName);
            if ~isfolder(saveDir)
                mkdir(saveDir);  % Create directory if needed
                fprintf('Created directory: %s\n', saveDir);
            end

            % Process each unit
            for u = 1:length(units)
                unitID = units{u};
                totalUnits = totalUnits + 1;

                % Display status message for tracking progress
                fprintf('Processing: Group: %s | Recording: %s | Unit: %s\n', ...
                        groupName, recordingName, unitID);

                try
                    % Extract data and metadata for the current unit
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    binEdges = unitData.binEdges;
                    fullPSTH = unitData.psthRaw;

                    % Validate the existence of required data
                    if isempty(binEdges) || isempty(fullPSTH)
                        warning('Skipping Unit %s: Missing data (PSTH or bin edges).\n', unitID);
                        continue;
                    end

                    % Prepare metadata for annotation
                    cellType = unitData.CellType;
                    templateChannel = unitData.TemplateChannel;
                    if unitData.IsSingleUnit == 1 % Set Single Unit Status
                        singleUnitStatus = "Single Unit";
                    else
                        singleUnitStatus = "Not Single Unit";
                    end

                    % Format metadata for display on the plot
                    metadataText = sprintf('Cell Type: %s | Channel: %d | %s | Unit ID: %s', ...
                                           cellType, templateChannel, singleUnitStatus, unitID);

                    % Generate plot title and save path
                    figTitle = sprintf('PSTH: %s - %s - %s', groupName, recordingName, unitID);
                    dateStr = datestr(now, 'yyyy-mm-dd_HH-MM');
                    fileName = sprintf('RawPSTH-%s_%s.png', unitID, dateStr);
                    fullPath = fullfile(saveDir, fileName);

                    % Plot and save the PSTH with metadata
                    plotAndSavePSTH(binEdges, fullPSTH, lineTime, figTitle, fullPath, metadataText);
                    fprintf('Successfully saved: %s\n', fullPath);
                    successCount = successCount + 1;

                catch ME
                    % Handle errors gracefully and continue processing
                    errorCount = errorCount + 1;
                    warning('Error processing Unit %s: %s', unitID, ME.message);
                end
            end
        end
    end

    % Display summary of processing results
    fprintf('\nProcessing completed.\n');
    fprintf('Total Units Processed: %d\n', totalUnits);
    fprintf('Successfully Processed: %d\n', successCount);
    fprintf('Errors Encountered: %d\n', errorCount);
end

%% Helper Function: Plot and Save a Single PSTH with Metadata
function plotAndSavePSTH(binEdges, fullPSTH, lineTime, figTitle, fullPath, metadataText)
    % Create a new figure
    f = figure;

    % Plot the PSTH as black bars
    bar(binEdges(1:end-1), fullPSTH, 'FaceColor', 'k', 'EdgeColor', 'k');

    % Add labels and title
    xlabel('Time (s)');
    ylabel('Firing Rate (spikes/s)');
    title(figTitle);

    % Add a vertical line if lineTime is provided
    if ~isempty(lineTime)
        hold on;
        xline(lineTime, 'r--', 'LineWidth', 2);
    end

    % Add metadata as text annotation at the bottom of the plot
    annotation('textbox', [0.1, 0.01, 0.8, 0.05], ...
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
