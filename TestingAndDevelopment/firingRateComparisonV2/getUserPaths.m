function [dataFilePath, figureFolder] = getUserPaths()
    % getUserPaths: Prompts the user to enter paths for the data file and figures folder.
    %
    % Outputs:
    %   - dataFilePath: Full path to the selected data file
    %   - figureFolder: Path to the folder where figures will be saved

    % Default folder and file names
    defaultDataFolder = '/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData';
    defaultDataFile = 'all_data.mat';
    defaultFigureFolder = '/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testFigures';

    % Define the prompts and default values for user input
    prompt = {'Enter Data Folder:', 'Enter Data File Name:', 'Enter Figures Folder:'};
    defaultValues = {defaultDataFolder, defaultDataFile, defaultFigureFolder};

    try
        % Open input dialog box
        userInput = inputdlg(prompt, 'Select Data File and Figures Folder', [1 50], defaultValues);

        % Handle user cancellation
        if isempty(userInput)
            error('UserInput:Cancelled', 'User cancelled the input. Exiting script.');
        end

        % Extract user inputs
        dataFolder = userInput{1};
        dataFile = userInput{2};
        figureFolder = userInput{3};

        % Generate the full file path for the data file
        dataFilePath = fullfile(dataFolder, dataFile);

        % Validate if the data file exists
        if ~isfile(dataFilePath)
            error('FileNotFound:DataFile', 'The specified data file does not exist: %s', dataFilePath);
        end

        % Ensure the figures folder exists (create if needed)
        try
            if ~isfolder(figureFolder)
                mkdir(figureFolder);
                fprintf('Created new figures folder: %s\n', figureFolder);
            end
        catch ME
            % Handle any errors during folder creation
            rethrow(ME);  % Rethrow the original error for detailed stack trace
        end

        % Display selected paths for verification
        fprintf('Selected Data File: %s\n', dataFilePath);
        fprintf('Selected Figures Folder: %s\n', figureFolder);

    catch ME
        % Handle all other errors gracefully and display error details
        fprintf('Error occurred: %s\n', ME.message);
        fprintf('Identifier: %s\n', ME.identifier);
        for k = 1:length(ME.stack)
            fprintf('In %s (line %d)\n', ME.stack(k).file, ME.stack(k).line);
        end
        rethrow(ME);  % Stop execution after logging the error
    end
end
