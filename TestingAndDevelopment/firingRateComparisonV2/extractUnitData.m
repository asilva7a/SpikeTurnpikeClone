function cellDataStruct = extractUnitData(all_data, saveFolder)
% extractUnitData 
%   Does what is says on the box
%   Extracts variables from all_data struct to create cellData struct
%   Saves cellData to user specified directory for later use
%   Clears workspace

%% Extract relevant data from all_data struct
    % Get group name 
    groupName = fieldnames(all_data); % List field
    group = groupName{2}; % Extract Pvalb group (assuming 2nd)

    % Get recording name
    recordingName = fieldnames(all_data.(group)); % List recording names
    recording = recordingName{2}; % Extract 'pvalb_hctztreat_0008_rec1'

    % Get unit info (assuming unit 'cid314' is the 32nd unit)
    unitID = fieldnames(all_data.(group).(recording)); % List unit IDs
    unit = unitID{32}; % extract unit data cid314

    % Extract the unit data
    unitData = all_data.(group).(recording).(unit);

%% Generate Struct for storing all_data and new data
    % Generate struct for storing extracted data and future analysis
    cellDataStruct = struct(); 

    % Extract Data and label for struct
    spikeTimes = unitData.SpikeTimes_all;
    samplingFrequency = unitData.Sampling_Frequency;
    cellType = unitData.Cell_Type;
    isSingleUnit = unitData.IsSingleUnit;
    durationInSeconds = unitData.Recording_Duration;

    % Store all relevant data in the r
    cellDataStruct.(groupName).(recordingName).(unitID) = struct( ...
        'spikeTimes', spikeTimes, ...
        'samplingFrequency', samplingFrequency, ...
        'cellType', cellType, ...
        'isSingleUnit', isSingleUnit, ...
        'frAvg', mean(firingRate), ...
        'pValue', pValue, ...
        'responseType', responseType, ...
        'recording', recordingName, ...
        'binWidth', binWidth, ...
        'recordingLength', Recording_Duration ...
     );

%% Save struct

% Specify save file name
saveFile = 'cellDataStruct.mat';

% Create full saving file path
savePath = fullfile(saveFolder, saveFile);

% Save struct to directory
save(savePath, 'cellDataStruct');
disp(['Struct saved to:', savePath]);

end