function generateFigureDirectories(cellDataStruct, figureFolder)
    % Initialize structure with all fields
    dirPaths = struct(...
        'exp', fullfile(figureFolder, '0. expFigures'), ...
        'groups', {cell(0)}, ...
        'groupFigs', {cell(0)}, ...
        'recordings', {cell(0)}, ...
        'recordingFigs', {cell(0)}, ...
        'units', {cell(0)});
    
    % Get all group names once
    groupNames = fieldnames(cellDataStruct);
    numGroups = length(groupNames);
    
    % Initialize cell arrays with correct size
    dirPaths.groups = cell(numGroups, 1);
    dirPaths.groupFigs = cell(numGroups, 1);
    dirPaths.recordings = cell(numGroups, 1);
    dirPaths.recordingFigs = cell(numGroups, 1);
    dirPaths.units = cell(numGroups, 1);
    
    % Create experiment level directory
    if ~isfolder(dirPaths.exp)
        mkdir(dirPaths.exp);
        fprintf('Created experiment figures directory: %s\n', dirPaths.exp);
    end
    
    % Create directories for each group
    for g = 1:numGroups
        groupName = groupNames{g};
        
        % Build group paths
        groupPath = fullfile(figureFolder, groupName);
        groupFigsPath = fullfile(groupPath, '0. groupFigures');
        
        % Store paths
        dirPaths.groups{g} = groupPath;
        dirPaths.groupFigs{g} = groupFigsPath;
        
        % Create directories
        if ~isfolder(groupPath)
            mkdir(groupPath);
            fprintf('Created group directory: %s\n', groupName);
        end
        if ~isfolder(groupFigsPath)
            mkdir(groupFigsPath);
            fprintf('Created group figures directory: %s\n', groupFigsPath);
        end
        
        % Process recordings
        recordings = fieldnames(cellDataStruct.(groupName));
        numRecordings = length(recordings);
        
        dirPaths.recordings{g} = cell(numRecordings, 1);
        dirPaths.recordingFigs{g} = cell(numRecordings, 1);
        dirPaths.units{g} = cell(numRecordings, 1);
        
        % Create recording and unit directories
        for r = 1:numRecordings
            recordingName = recordings{r};
            
            % Build paths
            recordingPath = fullfile(groupPath, recordingName);
            recordingFigsPath = fullfile(recordingPath, '0. recordingFigures');
            
            % Store paths
            dirPaths.recordings{g}{r} = recordingPath;
            dirPaths.recordingFigs{g}{r} = recordingFigsPath;
            
            % Create directories
            if ~isfolder(recordingPath)
                mkdir(recordingPath);
                fprintf('Created recording directory: %s\n', recordingName);
            end
            if ~isfolder(recordingFigsPath)
                mkdir(recordingFigsPath);
                fprintf('Created recording figures directory: %s\n', recordingFigsPath);
            end
            
            % Process units
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            numUnits = length(units);
            dirPaths.units{g}{r} = cell(numUnits, 1);
            
            for u = 1:numUnits
                unitID = units{u};
                unitPath = fullfile(recordingPath, unitID);
                dirPaths.units{g}{r}{u} = unitPath;
                
                if ~isfolder(unitPath)
                    mkdir(unitPath);
                    fprintf('Created unit directory: %s\n', unitID);
                end
            end
        end
    end
end

