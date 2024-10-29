function [cellDataStruct] = extractUnitData(all_data)
    % Debugging output
    disp('extractUnitData called');

    % Initialize the struct to ensure no previous data is carried over
    cellDataStruct = struct();

    %% Extract relevant data from all_data struct
    groupName = fieldnames(all_data);  
    group = groupName{2};  % Assuming 'Pvalb' is the second field

    recordingName = fieldnames(all_data.(group));  
    recording = recordingName{2};  % Assuming 'pvalb_hctztreat_0008_rec1'

    unitID = fieldnames(all_data.(group).(recording));  
    unit = unitID{32};  % Assuming 'cid314' is the 32nd unit

    % Extract the unit data
    unitData = all_data.(group).(recording).(unit);

    %% Dynamic Copy of Selected Fields Using Loop
    % Define the fields you want to copy
    fieldsToCopy = {
        'SpikeTimes_all', 'Sampling_Frequency', 'Cell_Type', ...
        'IsSingleUnit', 'Recording_Duration'
    };

    % Initialize an empty struct to store the copied fields
    newUnitStruct = struct();

    % Loop through the fields and copy the data
    for i = 1:numel(fieldsToCopy)
        field = fieldsToCopy{i};
        if isfield(unitData, field)
            % Use dynamic field assignment
            newUnitStruct.(strrep(field, '_', '')) = unitData.(field);
        else
            disp(['Warning: Field ' field ' not found in unitData.']);
        end
    end

    % Add additional fields manually as needed
    newUnitStruct.firingRate = [];
    newUnitStruct.treatmentMoment = [];
    newUnitStruct.psthRaw = [];
    newUnitStruct.psthSmoothed = [];
    newUnitStruct.pValue = [];
    newUnitStruct.responseType = [];
    newUnitStruct.recording = recording;
    newUnitStruct.binWidth = 0.1;

    % Store the new struct in the final output
    cellDataStruct.(group).(recording).(unit) = newUnitStruct;

    %% Handle Save Logic
    saveDir = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';
    savePath = fullfile(saveDir, 'cellDataStruct.mat');

    if isfile(savePath)
        disp('Overwriting existing file.');
        delete(savePath);  % Remove old file
    else
        disp('Saving new file.');
    end

    try
        save(savePath, 'cellDataStruct', '-v7');
        disp('Struct saved successfully.');
    catch ME
        disp('Error saving the file:');
        disp(ME.message);
    end

    % Display the struct for debugging
    disp('Struct after assignment:');
    disp(cellDataStruct);
end

%% To Do
%   Need:
%    1.
%   Want:
%    1. Arrange fields in struct in alphabetical order
