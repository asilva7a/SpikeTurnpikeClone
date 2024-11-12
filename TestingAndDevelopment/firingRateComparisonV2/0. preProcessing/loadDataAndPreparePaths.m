function [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = loadDataAndPreparePaths()
    % loadDataAndPreparePaths: Handles user input for paths and prepares file paths.
    
    %% Generate Paths
    % Default paths and filenames
    defaultDataFolder = '/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/figures_BinWidth-0.01s_Boxcar-21';
    defaultDataFile = 'all_data.mat';
    defaultFigureFolder = '/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testFigures';
    defaultCellStructFile = 'cellDataStruct.mat';

    % Define user input prompts
    prompt = {'Enter Data Folder:', 'Enter Data File Name:', 'Enter Figures Folder:'};
    defaultValues = {defaultDataFolder, defaultDataFile, defaultFigureFolder};

    try
        % Get user input with defaults
        userInput = inputdlg(prompt, 'Select Data and Figures Paths', [1 50], defaultValues);

        % Handle cancellation gracefully
        if isempty(userInput)
            error('UserInput:Cancelled', 'User cancelled the input. Exiting script.');
        end

        % Extract inputs from the user dialog
        dataFolder = userInput{1};
        dataFile = userInput{2};
        figureFolder = userInput{3};

        % Generate file paths
        dataFilePath = fullfile(dataFolder, dataFile);
        cellDataStructPath = fullfile(dataFolder, defaultCellStructFile);

        % Ensure the figures folder exists (create if needed)
        if ~isfolder(figureFolder)
            mkdir(figureFolder);
            fprintf('Created new figures folder: %s\n', figureFolder);
        end

        % Validate if the data file exists
        if ~isfile(dataFilePath)
            error('FileNotFound:DataFile', 'The data file does not exist: %s', dataFilePath);
        end

        % Display selected paths for confirmation
        fprintf('Data File: %s\n', dataFilePath);
        fprintf('Data File Path: %s/n',dataFilePath)
        fprintf('Figure Folder: %s\n', figureFolder);
        fprintf('')

        %% Save file paths to struct for debugging later
        % Create a structure to store all paths
        pathConfig = struct(...
            'dataFilePath', dataFilePath, ...
            'dataFolder', dataFolder, ...
            'cellDataStructPath', cellDataStructPath, ...
            'figureFolder', figureFolder);

        % Create config directory if it doesn't exist
        configDir = fullfile(dataFolder, 'config');
        if ~exist(configDir, 'dir')
            mkdir(configDir);
        end

        % Save paths to config file with timestamp
        timeStamp = datetime('now','Format', 'y-MMM-d_HH:mm:ss');
        configFileName = fullfile(configDir, sprintf('path_config_%s.mat', timeStamp));
        
        % Save the configuration
        save(configFileName, '-struct', 'pathConfig');
        fprintf('Path configuration saved to: %s\n', configFileName);

        % Ensure the figures folder exists (create if needed)
        if ~isfolder(figureFolder)
            mkdir(figureFolder);
            fprintf('Created new figures folder: %s\n', figureFolder);
        end

        % Validate if the data file exists
        if ~isfile(dataFilePath)
            error('FileNotFound:DataFile', 'The data file does not exist: %s', dataFilePath);
        end

    catch ME
        % Log errors and rethrow
        fprintf('Error occurred: %s\n', ME.message);
        fprintf('Identifier: %s\n', ME.identifier);
        for k = 1:length(ME.stack)
            fprintf('In %s (line %d)\n', ME.stack(k).file, ME.stack(k).line);
        end
        rethrow(ME);
    end
end
