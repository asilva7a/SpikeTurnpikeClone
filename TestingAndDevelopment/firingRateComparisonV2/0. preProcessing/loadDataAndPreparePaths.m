function [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = loadDataAndPreparePaths()
    % Constants
    DEFAULT_PATHS = struct(...
        'dataFolder', '/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/binWidth1.0s_boxCar10/projectData', ...
        'dataFile', 'all_data.mat', ...
        'figureFolder', '/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/binWidth1.0s_boxCar10/projectFigures', ...
        'cellStructFile', 'cellDataStruct.mat');
    
    try
        % Get user input
        paths = getUserInput(DEFAULT_PATHS);
        
        % Generate and validate paths
        [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = validateAndCreatePaths(paths);
        
        % Save configuration
        savePathConfig(paths, dataFolder);
        
        % Display paths
        displayPaths(dataFilePath, figureFolder);
        
    catch ME
        handleError(ME);
    end
end

function paths = getUserInput(defaults)
    % Define prompts
    prompts = {'Enter Data Folder:', 'Enter Data File Name:', 'Enter Figures Folder:'};
    defaultValues = {defaults.dataFolder, defaults.dataFile, defaults.figureFolder};
    
    % Get user input
    userInput = inputdlg(prompts, 'Select Data and Figures Paths', [1 50], defaultValues);
    
    % Check for cancellation
    if isempty(userInput)
        error('UserInput:Cancelled', 'User cancelled the input. Exiting script.');
    end
    
    % Store paths
    paths = struct(...
        'dataFolder', userInput{1}, ...
        'dataFile', userInput{2}, ...
        'figureFolder', userInput{3}, ...
        'cellStructFile', defaults.cellStructFile);
end

function [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = validateAndCreatePaths(paths)
    % Generate file paths
    dataFilePath = fullfile(paths.dataFolder, paths.dataFile);
    dataFolder = paths.dataFolder;
    cellDataStructPath = fullfile(paths.dataFolder, paths.cellStructFile);
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
    pathConfig = struct(...
        'dataFilePath', fullfile(paths.dataFolder, paths.dataFile), ...
        'dataFolder', paths.dataFolder, ...
        'cellDataStructPath', fullfile(paths.dataFolder, paths.cellStructFile), ...
        'figureFolder', paths.figureFolder);
    
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
    fprintf('\n');
end

function handleError(ME)
    fprintf('Error: %s\n', ME.message);
    fprintf('In: %s\n', ME.identifier);
    
    % Print stack trace
    for k = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(k).file, ME.stack(k).line);
    end
    
    rethrow(ME);
end

