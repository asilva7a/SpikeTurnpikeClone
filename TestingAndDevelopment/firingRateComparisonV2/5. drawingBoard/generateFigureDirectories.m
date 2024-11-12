function generateFigureDirectories(cellDataStruct, figureFolder)
    % Base directory path
    baseDir = figureFolder;
    
    % Ensure base directory exists
    if ~isfolder(baseDir)
        mkdir(baseDir);
        fprintf('Created new base figures folder: %s\n', baseDir);
    end
    
    % Get group names
    groupNames = fieldnames(cellDataStruct);
    
    % Loop through each group
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        % Create group directory
        groupPath = fullfile(baseDir, groupName);
        if ~exist(groupPath, 'dir')
            mkdir(groupPath);
            fprintf('Created group folder: %s\n', groupName);
        end
        
        % Get recordings for this group
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Loop through each recording
        for r = 1:length(recordings)
            recordingName = recordings{r};
            % Create recording directory
            recordingPath = fullfile(groupPath, recordingName);
            if ~exist(recordingPath, 'dir')
                mkdir(recordingPath);
                fprintf('Created recording folder: %s\n', recordingName);
            end       
        end
    end
end