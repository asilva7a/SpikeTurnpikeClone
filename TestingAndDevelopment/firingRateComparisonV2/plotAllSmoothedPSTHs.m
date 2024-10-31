function plotAllSmoothedPSTHs(cellDataStruct, lineTime, figureFolder)
    % plotAllSmoothedPSTHs: Plots and saves smoothed PSTHs for all units with metadata.
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

    if nargin < 3 || isempty(figureFolder)
        error('Figure folder path is required. Please provide a valid folder path.');
    end

    % Define "Smoothed PSTHs" subdirectory within the provided figure folder
    smoothedPSTHFolder = fullfile(figureFolder, 'Smoothed PSTHs');

    % Ensure the "Smoothed PSTHs" folder exists
    if ~isfolder(smoothedPSTHFolder)
        mkdir(smoothedPSTHFolder);
        fprintf('Created "Smoothed PSTHs" folder: %s\n', smoothedPSTHFolder);
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

            % Create a subdirectory for each group and recording within "Smoothed PSTHs"
            saveDir = fullfile(smoothedPSTHFolder, groupName, recordingName);
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
                    smoothPSTH = unitData.psthSmoothed;

                    if isempty(binEdges) || isempty(smoothPSTH)
                        warning('Skipping Unit %s: Missing smoothed PSTH or bin edges.\n', unitID);
                        continue;
                    end

                    % Prepare metadata for the plot
                    metadataText = generateMetadataText(unitData, unitID);

                    % Generate plot title and save path
                    figTitle = sprintf('Smoothed PSTH: %s - %s - %s', groupName, recordingName, unitID);
                    timestamp = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss');
                    fileName = sprintf('smoothedPSTH-%s_%s.png', unitID, char(timestamp));
                    fullPath = fullfile(saveDir, fileName);

                    % Plot and save the smoothed PSTH with metadata
                    plotPSTHsmooth(binEdges, smoothPSTH, lineTime, figTitle, saveDir, unitID);
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
