function generateFigureDirectories(cellDataStruct, figureFolder)
    % Base directory path
    baseDir = figureFolder;
    
    % Get group names
    groupNames = fieldnames(cellDataStruct);
    
    if ~isfolder(baseDir)
        mkdir(baseDir);
        fprintf('Created new base figures folder: %s\n', baseDir);
    end

    % Loop through each group
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        % Create group directory
        groupPath = fullfile(baseDir, groupName);
        if ~exist(groupPath, 'dir')
            mkdir(groupPath);
            fprintf('Created group folder: %s\n', groupName);
        end

        % Create group level figure folder
        groupFigures = fullfile(groupPath, '0.groupFigures');
        if ~exist(groupFigures, 'dir')
            mkdir(groupFigures);
            fprintf('Created group figure folder: %s\n', groupFigures);
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

                % Create recording level figure directory
                recordingFigures = fullfile(recordingPath, '0.recordingFigures');
                if ~exist(recordingFigures, 'dir')
                    mkdir(recordingFigures);
                    fprintf('Created recording figure folder: %s\n', recordingFigures);
                end
            end
        end
    end
end
