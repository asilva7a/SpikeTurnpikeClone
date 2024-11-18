function [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = validateAndCreatePaths(paths)
    % Generate file paths
    dataFilePath = fullfile(paths.dataFolder, paths.dataFile);
    dataFolder = paths.dataFolder;
    
    % Create data folder for cellDataStruct and backups
    dataDir = fullfile(dataFolder, 'data');
    if ~isfolder(dataDir)
        mkdir(dataDir);
        fprintf('Created data directory: %s\n', dataDir);
    end
    
    % Update cellDataStruct path to be in data folder
    cellDataStructPath = fullfile(dataDir, paths.cellStructFile);
    figureFolder = paths.figureFolder;
    
    % Validate data file
    if ~isfile(dataFilePath)
        error('FileNotFound:DataFile', 'Data file not found: %s', dataFilePath);
    end
    
    % Create figures folder if needed
    if ~isfolder(figureFolder)
        mkdir(figureFolder);
        fprintf('Created figures folder: %s\n', figureFolder);
    end
end

function savePathConfig(paths, dataFolder)
    % Create config structure
    dataDir = fullfile(dataFolder, 'data');  % Use data subdirectory
    pathConfig = struct(...
        'dataFilePath', fullfile(paths.dataFolder, paths.dataFile), ...
        'dataFolder', paths.dataFolder, ...
        'cellDataStructPath', fullfile(dataDir, paths.cellStructFile), ...  % Updated path
        'figureFolder', paths.figureFolder, ...
        'dataDir', dataDir);  % Add data directory to config
    
    % Create config directory
    configDir = fullfile(dataFolder, 'config');
    if ~isfolder(configDir)
        mkdir(configDir);
    end
    
    % Save config
    timeStamp = datetime('now', 'Format', 'y-MMM-d_HH-mm-ss');
    configFile = fullfile(configDir, sprintf('path_config_%s.mat', timeStamp));
    save(configFile, '-struct', 'pathConfig');
    fprintf('Configuration saved: %s\n', configFile);
end

function displayPaths(dataFilePath, figureFolder)
    fprintf('Data File: %s\n', dataFilePath);
    fprintf('Figure Folder: %s\n', figureFolder);
    fprintf('Data Directory: %s\n', fullfile(fileparts(dataFilePath), 'data'));
    fprintf('\n');
end

