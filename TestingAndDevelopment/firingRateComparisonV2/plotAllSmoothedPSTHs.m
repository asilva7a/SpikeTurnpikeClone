function plotAllSmoothedPSTHs(cellDataStruct, lineTime, figureFolder)
    % plotAllSmoothedPSTHs: Plots and saves smoothed PSTHs for all units with metadata.
    %
    % Inputs:
    %   - cellDataStruct: Struct containing the PSTH data.
    %   - lineTime: Time (in seconds) to draw a vertical line (optional).
    %   - figureFolder: Base folder where the raw figures are saved.

    %% Set Default Arguments
    if nargin < 2 || isempty(lineTime)
        lineTime = 1860;  % Default treatment moment
        fprintf('No treatment period specified. Defaulting to 1860s.\n');
    end

    if nargin < 3 || isempty(figureFolder)
        error('Figure folder path is required. Please provide a valid folder path.');
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

            % Define the directory for smoothed PSTHs within the existing raw PSTH directory
            saveDir = fullfile(figureFolder, groupName, recordingName, 'Smoothed PSTHs');
            if ~isfolder(saveDir)
                mkdir(saveDir);
                fprintf('Created directory for smoothed PSTHs: %s\n', saveDir);
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
                    smoothPSTH = unitData.psthSmoothed;

                    if isempty(binEdges) || isempty(smoothPSTH)
                        warning('Skipping Unit %s: Missing smoothed PSTH or bin edges.\n', unitID);
                        continue;
                    end

                    % Prepare metadata for the plot
                    cellType = unitData.CellType;
                    templateChannel = unitData.TemplateChannel;
                    singleUnitStatus = "Single Unit";
                    if unitData.IsSingleUnit == 0
                        singleUnitStatus = "Not Single Unit";
                    end
                    metadataText = sprintf('Cell Type: %s | Channel: %d | %s | Unit ID: %s', ...
                                           cellType, templateChannel, singleUnitStatus, unitID);

                    % Generate plot title and save path
                    figTitle = sprintf('Smoothed PSTH: %s - %s - %s', groupName, recordingName, unitID);
                    timestamp = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss');
                    fileName = sprintf('smoothedPSTH-%s_%s.png', unitID, char(timestamp));
                    fullPath = fullfile(saveDir, fileName);

                    % Plot and save the smoothed PSTH with metadata
                    plotAndSavePSTH(binEdges, smoothPSTH, lineTime, figTitle, fullPath, metadataText);
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

    % Display summary of results
    fprintf('\nProcessing completed.\n');
    fprintf('Total Units Processed: %d\n', totalUnits);
    fprintf('Successfully Processed: %d\n', successCount);
    fprintf('Errors Encountered: %d\n', errorCount);
end
