function [cellDataStruct] = loadDataAndExtractUnits(dataFilePath, all_data)

    % Prompts for User Input
    prompt = {'Enter Data Folder:', 'Enter Data File Name:'};
    defaultValues = {defaultDataFolder, defaultDataFile};

    try
        %% Get User Input
        userInput = inputdlg(prompt, 'Select Data File', [1 50], defaultValues);

        % Handle user cancellation
        if isempty(userInput)
            error('UserInput:Cancelled', 'User cancelled the input. Exiting script.');
        end

        % Extract user inputs
        dataFolder = userInput{1};
        dataFile = userInput{2};
        dataFilePath = fullfile(dataFolder, dataFile);
        cellDataStructPath = fullfile(dataFolder, defaultCellStructFile);

        %% Load Data File
        if isfile(dataFilePath)
            load(dataFilePath, 'all_data');
            disp('Data file loaded successfully!');
        else
            error('FileNotFound:DataFile', 'The specified data file does not exist: %s', dataFilePath);
        end

        %% Call extractUnitData to Process and Save the Struct
        disp('Calling extractUnitData...');
        extractUnitData(all_data);  % Extract and save the struct

        %% Load and Display the Saved Struct
        try
            load(cellDataStructPath, 'cellDataStruct');
            disp('Loaded cellDataStruct.mat successfully!');

            % Display the struct as a table for debugging
            disp('Displaying cellDataStruct as table:');
            disp(struct2table(cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1, "AsArray", true));
        catch ME
            error('Error loading cellDataStruct.mat: %s', ME.message);
        end

    catch ME
        % Display detailed error information
        fprintf('An error occurred: %s\n', ME.message);
        fprintf('Identifier: %s\n', ME.identifier);
        for k = 1:length(ME.stack)
            fprintf('In %s (line %d)\n', ME.stack(k).file, ME.stack(k).line);
        end
    end
end
