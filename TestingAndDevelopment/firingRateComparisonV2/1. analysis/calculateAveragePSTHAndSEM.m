function cellDataStruct = calculateAveragePSTHAndSEM(cellDataStruct, dataFolder)
    % calculateAveragePSTHAndSEM: Computes average and SEM of PSTHs for each recording.
    % Adds the mean and SEM PSTH to cellDataStruct under the 'recordingData' field at the recording level.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - dataFolder: Directory where the updated cellDataStruct will be saved.
    %
    % Outputs:
    %   - cellDataStruct: Updated structure with mean and SEM PSTH stored under 'recordingData' for each recording.

    % Verify the data folder path
    if nargin < 2 || isempty(dataFolder)
        error('Please specify a valid dataFolder path for saving the cellDataStruct.');
    end

    % Set full path for saving the struct
    cellDataStructPath = fullfile(dataFolder, 'cellDataStruct.mat');

    % Loop through each group and recording
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        fprintf('Processing Group: %s\n', groupName);  % Debug statement

        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            fprintf('  Processing Recording: %s\n', recordingName);  % Debug statement

            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            numUnits = numel(units);  % Number of units for preallocation

            % Preallocate PSTH data for calculations
            psthLength = length(cellDataStruct.(groupName).(recordingName).(units{1}).psthSmoothed);
            allPSTHs = NaN(numUnits, psthLength);  % Array to store all PSTHs for averaging

            % Collect PSTHs for all units in the recording
            for u = 1:numUnits
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                if isfield(unitData, 'psthSmoothed')
                    psth = unitData.psthSmoothed;
                    
                    if length(psth) == psthLength  % Ensure consistent length
                        allPSTHs(u, :) = psth;
                        fprintf('    Processed Unit: %s\n', unitID);  % Debug statement
                    else
                        warning('PSTH length mismatch for Unit %s in Recording %s. Skipping this unit.', unitID, recordingName);
                    end
                else
                    warning('No psthSmoothed field found for Unit %s in Recording %s. Skipping this unit.', unitID, recordingName);
                end
            end

            % Calculate mean and SEM across units, ignoring NaNs
            avgPSTH = mean(allPSTHs, 1, 'omitnan');
            semPSTH = std(allPSTHs, 0, 1, 'omitnan') / sqrt(numUnits);

            % Store average and SEM PSTH under 'recordingData' in the struct
            cellDataStruct.(groupName).(recordingName).recordingData.avgPSTH = avgPSTH;
            cellDataStruct.(groupName).(recordingName).recordingData.semPSTH = semPSTH;
            fprintf('  Calculated avgPSTH and semPSTH for Recording: %s\n', recordingName);  % Debug statement
        end
    end

    % Try to save the struct and handle any errors
    try
        % Save the struct with optional compression (-v7.3 for large data)
        save(cellDataStructPath, 'cellDataStruct', '-v7.3');
        fprintf('Saved cellDataStruct to: %s\n', cellDataStructPath);

        % Verify if the file was saved successfully
        if ~isfile(cellDataStructPath)
            error('SaveError:VerificationFailed', 'Failed to verify the saved file: %s', cellDataStructPath);
        end

    catch ME
        % Handle and log any save-related errors
        fprintf('Error occurred during saving: %s\n', ME.message);
        fprintf('Identifier: %s\n', ME.identifier);
        for k = 1:length(ME.stack)
            fprintf('In %s (line %d)\n', ME.stack(k).file, ME.stack(k).line);
        end
        rethrow(ME);  % Rethrow the error after logging
    end
end
