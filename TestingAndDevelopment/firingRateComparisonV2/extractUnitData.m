function cellDataStruct = extractUnitData(all_data, saveFolder)
% extractUnitData 
%   Does what is says on the box
%   Extracts variables from all_data struct to create cellData struct
%   Saves cellData to user specified directory for later use
%   Clears workspace

%% Extract relevant data from all_data struct
    % Get group name (assuming 'Pvalb' is the 2nd field)
    groupName = fieldnames(all_data);  
    group = groupName{2};  

    % Get recording name (assuming it's the 2nd recording)
    recordingName = fieldnames(all_data.(group));  
    recording = recordingName{2};  

    % Get unit info (assuming 'cid314' is the 32nd unit)
    unitID = fieldnames(all_data.(group).(recording));  
    unit = unitID{32};  

    % Extract the unit data
    unitData = all_data.(group).(recording).(unit);

    %% Generate Struct for storing extracted data
    cellDataStruct = struct();  

    % Extract data from the struct fields
    spikeTimes = unitData.SpikeTimes_all;
    samplingFrequency = unitData.Sampling_Frequency;
    cellType = unitData.Cell_Type;
    isSingleUnit = unitData.IsSingleUnit;
    recordingLength = unitData.Recording_Duration;
    binWidth = 0.1;  % Bin width in seconds

    % Store relevant data in the struct
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

    %% Handle the Save Directory and Save the Struct
    % Check if the save folder exists, if not, create it
    if ~exist(saveFolder, 'dir')
        mkdir(saveFolder);
        disp(['Directory created: ', saveFolder]);
    end

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