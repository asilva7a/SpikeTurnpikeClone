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
    recordingLength = unitData.Recording_Duration;
    binWidth = 0.1; % Set bin width in ms

    % Store all relevant data in the struct
    cellDataStruct.(group).(recording).(unit) = struct( ...
        'spikeTimes', spikeTimes, ...
        'samplingFrequency', samplingFrequency, ...
        'cellType', cellType, ...
        'isSingleUnit', isSingleUnit, ...
        'firingRate', [], ...
        'treatmentMoment', [], ...
        'psthRaw', [], ...
        'psthSmoothed', [], ...
        'pValue', [], ...
        'responseType', [], ...
        'recording', recordingName, ...
        'binWidth', binWidth, ...
        'recordingLength', recordingLength ...
     );

%% Save struct

% Define the save file name and path
    saveFile = 'cellDataStruct.mat';
    savePath = fullfile(saveFolder, saveFile);

    % Save the struct to the specified directory
    try
        save(savePath, 'cellDataStruct');
        disp(['Struct saved to: ', savePath]);
    catch ME
        disp('Error saving the file:');
        disp(ME.message);
    end

    %% Optional: Clear local variables to prevent workspace clutter
    clear groupName group recordingName recording unitID unit unitData ...
          spikeTimes samplingFrequency cellType isSingleUnit ...
          recordingLength binWidth saveFile savePath;

end