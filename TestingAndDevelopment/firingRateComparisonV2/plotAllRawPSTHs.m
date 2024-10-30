function plotAllRawPSTHs(cellDataStruct, lineTime)
    % plotAllPSTHs: Plots and saves PSTHs for all units in the structure.
    %
    % Inputs:
    %   - cellDataStruct: Struct containing the PSTH data.
    %   - lineTime: Optional time (in seconds) to add a vertical line.
    
    % Set up the save directory for figures
    baseDir = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestFigures';
    
    if ~isfolder(baseDir)
        mkdir(baseDir);  % Create directory if it doesn't exist
        fprintf('Created new directory: %s\n', baseDir);
    end

    % Track total units processed
    totalUnits = 0;
    successCount = 0;
    errorCount = 0;

    % Loop over all groups, recordings, and units
    groupNames = fieldnames(cellDataStruct);

    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Create the group directory
            saveDir = fullfile(baseDir, groupName, recordingName);

            if ~isfolder(saveDir)
                mkdir(saveDir);  % Create the directory if it doesn't exist
                fprintf('Created directory: %s\n', saveDir);
            end
            
            % Proceed with loop
            for u = 1:length(units)
                unitID = units{u};
                totalUnits = totalUnits + 1;  % Track total units processed

                % Display status message for progress tracking
                fprintf('Processing: Group: %s | Recording: %s | Unit: %s\n', ...
                    groupName, recordingName, unitID);

                % Extract metadata and PSTH data
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                binEdges = unitData.binEdges;
                fullPSTH = unitData.psthRaw;

                % Validate data existence
                if isempty(binEdges) || isempty(fullPSTH)
                    warning('Skipping Unit %s: Missing data (PSTH or bin edges).\n', unitID);
                    continue;
                end

                % Extract metadata for annotation
                cellType = unitData.CellType;
                templateChannel = unitData.Template_Channel;
                isSingleUnit = unitData.IsSingleUnit;
                singleUnitStatus = "Single Unit";
                if ~isSingleUnit
                    singleUnitStatus = "Not Single Unit";
                end

                % Generate the metadata text for the figure
                metadataText = sprintf( ...
                    'Cell Type: %s | Channel: %d | %s | Unit ID: %s', ...
                    cellType, templateChannel, singleUnitStatus, unitID);

                % Generate a plot title
                figTitle = sprintf('PSTH: %s - %s - %s', groupName, recordingName, unitID);

                % Construct a file name based on the unit and timestamp
                dateStr = datestr(now, 'yyyy-mm-dd_HH-MM');
                fileName = sprintf('RawPSTH-%s_%s.png', unitID, dateStr);
                fullPath = fullfile(saveDir, fileName);
                % Try to extract and plot the PSTH data

                    try
                    % Extract bin edges and raw PSTH
                    binEdges = cellDataStruct.(groupName).(recordingName).(unitID).binEdges;
                    fullPSTH = cellDataStruct.(groupName).(recordingName).(unitID).psthRaw;

                    % Validate data existence
                    if isempty(binEdges) || isempty(fullPSTH)
                        warning('Skipping Unit %s: Missing data (PSTH or bin edges).\n', unitID);
                        continue;
                    end

                    % Generate a plot title
                    figTitle = sprintf('PSTH: %s - %s - %s', groupName, recordingName, unitID);

                    % Construct a file name based on unit and timestamp
                    dateStr = datestr(now, 'yyyy-mm-dd_HH-MM');
                    fileName = sprintf('RawPSTH-%s_%s.png', unitID, dateStr);
                    fullPath = fullfile(saveDir, fileName);
                    
                    % Plot and save the PSTH with metadata
                    try
                    plotAndSavePSTH(binEdges, fullPSTH, lineTime, figTitle, fullPath, metadataText);
                    fprintf('Saved: %s\n', fullPath);

                    % If successful, update success counter and print message
                    successCount = successCount + 1;
                    fprintf('Successfully saved: %s\n', fullPath);

                    catch ME
                        % If an error occurs, log the error and update the error counter
                        errorCount = errorCount + 1;
                        warning('Error processing Unit %s: %s', unitID, ME.message);
                    end
                end
            end
        end
        
        fprintf('\nAll PSTHs processed and saved.\n');
    
    end

    % Summary message
    fprintf('\nProcessing completed.\n');
    fprintf('Total Units Processed: %d\n', totalUnits);
    fprintf('Successfully Processed: %d\n', successCount);
    fprintf('Errors Encountered: %d\n', errorCount);
end

%% Helper Function: Plot and Save a Single PSTH
function plotAndSavePSTH(binEdges, fullPSTH, lineTime, figTitle, fullPath, metadataText)
    % plotAndSavePSTH: Plots a single PSTH and saves it as a PNG.
    
    % Create a new figure
    f = figure;

    % Plot the PSTH as black bars
    bar(binEdges(1:end-1), fullPSTH, 'FaceColor', 'k', 'EdgeColor', 'k');

    % Add labels and title
    xlabel('Time (s)');
    ylabel('Firing Rate (spikes/s)');
    if ~isempty(figTitle)
        title(figTitle);
    else
        title('Peri-Stimulus Time Histogram (PSTH)');
    end

    % Add a vertical line if lineTime is provided
    if ~isempty(lineTime)
        hold on;
        xline(lineTime, 'r--', 'LineWidth', 2);
    end
    
    % Add metadata text at the bottom of the figure
    annotation('textbox', [0.1, 0.01, 0.8, 0.05], ...  % Position: [x, y, width, height]
               'String', metadataText, ...
               'EdgeColor', 'none', ...
               'HorizontalAlignment', 'center', ...
               'FontSize', 10, ...
               'Interpreter', 'none');  % Prevent special character interpretation

    % Improve plot appearance
    grid off;
    set(gca, 'Box', 'off', 'TickDir', 'out');

    % Save the figure as a PNG with high resolution
    exportgraphics(f, fullPath, 'Resolution', 300);

    % Close the figure to avoid memory issues
    close(f);
end
