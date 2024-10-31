function [cellDataStruct] = extractUnitData(all_data, cellDataStructPath)

    % Debugging output
    disp('extractUnitData called');

    % Initialize the struct to ensure no previous data is carried over
    cellDataStruct = struct();

    %% Extract relevant data from all_data struct

    % Iterate over all groups, recordings, and units
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(all_data.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = (fieldnames(all_data.(groupName).(recordingName)));

            for u = 1:length(units)
                unitID = units{u};
                unitData = all_data.(groupName).(recordingName).(unitID);
                
                % Debugging: Display unit being processed
                fprintf('Processing Group: %s | Recording: %s | Unit: %s\n', ...
                        groupName, recordingName, unitID);

                %% Dynamic Copy of Selected Fields Using Loop
                % Define the fields you want to copy
                fieldsToCopy = {
                    'SpikeTimes_all', 'Sampling_Frequency', 'Cell_Type', ...
                    'IsSingleUnit', 'Recording_Duration', 'Depth', ...
                    'Template_Channel', 'Template_Channel_Position'
                };

                % Initialize an empty struct for the new unit
                newUnitStruct = struct();
          
                % Copy the required fields dynamically
                for i = 1:numel(fieldsToCopy)
                    field = fieldsToCopy{i};
                    if isfield(unitData, field)
                        % Assign and clean up the field name
                        newFieldName = strrep(field, '_', '');
                        newUnitStruct.(newFieldName) = unitData.(field);
                    else
                        % Display a warning with the missing field name
                        warning('Field "%s" not found for Unit: %s.', field, unitID);
                    end
                end

                % Add additional fields manually as needed
                newUnitStruct.firingRate = [];
                newUnitStruct.treatmentMoment = [];
                newUnitStruct.psthRaw = [];
                newUnitStruct.psthSmoothed = [];
                newUnitStruct.pValue = [];
                newUnitStruct.responseType = [];
                newUnitStruct.recording = recordingName;
                newUnitStruct.binWidth = 0.1;
                newUnitStruct.binEdges = [];
                newUnitStruct.numBins = [];

                % Store the new struct in the final output
                cellDataStruct.(groupName).(recordingName).(unitID) = newUnitStruct;
              
             end
         end
    end

    % Handle saving logic with backup and error handling
    try
        % Check if the file already exists
        if isfile(cellDataStructPath)
            % Create a backup of the existing file
            backupPath = strrep(cellDataStructPath, '.mat', ['_backup_' datestr(now, 'yyyy-mm-dd_HH-MM-SS') '.mat']);
            movefile(cellDataStructPath, backupPath);
            fprintf('Existing file backed up as: %s\n', backupPath);
        end

        % Save the struct with optional compression (-v7.3 for large data)
        save(cellDataStructPath, 'cellDataStruct', '-v7');
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


