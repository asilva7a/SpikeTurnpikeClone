function [cellDataStruct] = smoothAllPSTHs(cellDataStruct, dataFilePath, windowSize)
    % smoothAllPSTHs: Smooths the raw PSTH for all units using a boxcar filter.
    %
    % Inputs:
    %   - cellDataStruct: Input structure containing raw PSTH data
    %   - windowSize: Size of the smoothing window (default = 5)
    %
    % Output:
    %   - cellDataStruct: Updated structure with smoothed PSTHs

    % Set default window size if not provided
    if nargin < 3
        windowSize = 5;
    end

    % Define the boxcar filter for smoothing
    boxcar = ones(1, windowSize) / windowSize;

    % Loop over all groups, recordings, and units in the structure
    groupNames = fieldnames(cellDataStruct);

    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};

                % Display progress for debugging
                fprintf('Smoothing PSTH: Group: %s | Recording: %s | Unit: %s\n', ...
                    groupName, recordingName, unitID);

                % Extract the raw PSTH for the current unit
                psthRough = cellDataStruct.(groupName).(recordingName).(unitID).psthRaw;

                % Check if the raw PSTH exists
                if isempty(psthRough)
                    warning('No raw PSTH found for Unit: %s. Skipping.', unitID);
                    continue;
                end

                % Apply smoothing using convolution
                smoothedPSTH = conv(psthRough, boxcar, 'same');

                % Save the smoothed PSTH back to the struct
                cellDataStruct.(groupName).(recordingName).(unitID).psthSmoothed = smoothedPSTH;
            end
        end
    end

    % Save the updated struct to the specified data file path
    try
        save(dataFilePath, 'cellDataStruct', '-v7');
        fprintf('Struct saved successfully to: %s\n', dataFilePath);
    catch ME
        fprintf('Error saving the file: %s\n', ME.message);
    end
end

