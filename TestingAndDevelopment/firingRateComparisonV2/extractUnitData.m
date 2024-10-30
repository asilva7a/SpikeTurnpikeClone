function [cellDataStruct] = extractUnitData(all_data)
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

                % Store the new struct in the final output
                cellDataStruct.(groupName).(recordingName).(unitID) = newUnitStruct;
              
             end
         end
    end

    %% Handle Save Logic
    saveDir = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';
    savePath = fullfile(saveDir, 'cellDataStruct.mat');

    % Check if the file already exists and delete if necessary
    if isfile(savePath)
        disp('Overwriting existing file.');
        delete(savePath);  % Remove the old file
    else
        disp('Saving new file.');
    end

    % Save the final struct to a .mat file
    try
        save(savePath, 'cellDataStruct', '-v7');
        disp('Struct saved successfully.');
    catch ME
        % Handle and display any saving errors
        disp('Error saving the file:');
        disp(ME.message);
    end

end

