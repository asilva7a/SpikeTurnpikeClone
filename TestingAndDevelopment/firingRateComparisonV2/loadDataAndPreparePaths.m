function [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = loadDataAndPreparePaths()
    % loadDataAndPreparePaths: Handles user input for paths and prepares file paths.
    
    % Default paths and filenames
    defaultDataFolder = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';
    defaultDataFile = 'all_data.mat';
    defaultFigureFolder = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';
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
