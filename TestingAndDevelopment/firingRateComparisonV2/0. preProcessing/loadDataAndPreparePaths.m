function [dataFilePath, dataFolder, cellDataStructPath, figureFolder] = loadDataAndPreparePaths()
    % loadDataAndPreparePaths: Prompts user to select directories for data and figure storage.
    
    % Default filenames (within selected folders)
    defaultDataFile = 'all_data.mat';
    defaultCellStructFile = 'cellDataStruct.mat';

    try
        % Prompt user to select Data Folder
        dataFolder = uigetdir('', 'Select the Data Folder');
        if dataFolder == 0
            error('UserInput:Cancelled', 'No Data Folder selected. Exiting script.');
        end

        % Prompt user to select Figures Folder
        figureFolder = uigetdir('', 'Select the Figures Folder');
        if figureFolder == 0
            error('UserInput:Cancelled', 'No Figures Folder selected. Exiting script.');
        end

        % Generate file paths
        dataFilePath = fullfile(dataFolder, defaultDataFile);
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
        fprintf('Data Folder: %s\n', dataFolder);
        fprintf('Figure Folder: %s\n', figureFolder);

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
