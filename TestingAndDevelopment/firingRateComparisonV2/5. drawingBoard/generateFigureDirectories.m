function generateFigureDirectories(cellDataStruct, figureFolder)
    % Base directory path
    baseDir = figureFolder;
    
    % Get group names
    groupNames = fieldnames(cellDataStruct);
    
    % Loop through each group
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        % Create group directory
        groupPath = fullfile(baseDir, groupName);
        mkdir(groupPath);
        
        % Get recordings for this group
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Loop through each recording
        for r = 1:length(recordings)
            recordingName = recordings{r};
            % Create recording directory
            recordingPath = fullfile(groupPath, recordingName);
            mkdir(recordingPath);

        end
    end
end