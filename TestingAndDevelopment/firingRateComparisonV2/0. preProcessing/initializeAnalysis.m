function [params, paths] = initializeAnalysis()
% initializeAnalysis - Set up the analysis environment and parameters
    %
    % This function initializes the analysis by setting up the project directory,
    % collecting analysis parameters, creating necessary directories, and saving
    % the configuration.
    %
    % Outputs:
    %   params - Structure containing analysis parameters
    %   paths - Structure containing file and directory paths

%% Main Function
    fprintf('\n=== Firing Rate Analysis Initialization ===\n\n');
    
    % Get project directory and validate
    projectDir = getProjectDirectory();
    validateProjectStructure(projectDir);
    
    % Get analysis parameters
    params = getAnalysisParams();
    
    % Setup directories
    paths = setupDirectoryStructure(projectDir, params);
    
    % Save configuration to analysis directory
    saveConfiguration(params, paths);
    
    % Display configuration summary
    displayConfiguration(params, paths);
end

% Get Project Directory and Defaults
function projectDir = getProjectDirectory()
    % Check for saved default directory
    defaultFile = 'defaultProjectDir.mat';
    
    if isfile(defaultFile)
        load(defaultFile, 'lastUsedDir');
        
        % Ask user if they want to use the last directory
        fprintf('\nLast used directory: %s\n', lastUsedDir);
        useLastDir = input('Use this directory? (y/n): ', 's');
        
        if strcmpi(useLastDir, 'y')
            projectDir = lastUsedDir;
            return;
        end
    end
    
    % Get new directory if no default or user wants new
    projectDir = uigetdir('~/', 'Select Project Directory containing SpikeStuff folder');
    if projectDir == 0
        error('User cancelled directory selection');
    end
    
    % Ask if user wants to save this as default
    saveAsDefault = input('Save this as default directory? (y/n): ', 's');
    if strcmpi(saveAsDefault, 'y')
        lastUsedDir = projectDir;
        save(defaultFile, 'lastUsedDir');
        fprintf('Directory saved as default.\n');
    end
end



function params = getAnalysisParams()
    % Collect analysis parameters from user
    fprintf('Setting Analysis Parameters:\n');
    fprintf('----------------------------\n');
    
    params.binWidth = getValidNumericInput('Enter bin width (seconds): ', 0);
    params.boxCarWindow = getValidNumericInput('Enter smoothing window size (seconds): ', 0);
    params.treatmentTime = getValidNumericInput('Enter treatment time (seconds): ', 0);
    params.recordingPeriod = getValidNumericInput('Enter total recording period (seconds): ', params.treatmentTime);

    % Get Baseline Window
    defaultPreWindow = [300 1800];
    fprintf('Enter Baseline Window [start end] (default: [%d %d]): ', ...
        defaultPreWindow(1), defaultPreWindow(2));
    params.preWindow = getValidWindowInput(defaultPreWindow);
    
    % Get Post-Treatment Window
    defaultPostWindow = [2000 3800];
    fprintf('Enter Post-Treatment Window [start end] (default: [%d %d]): ', ...
        defaultPostWindow(1), defaultPostWindow(2));
    params.postWindow = getValidWindowInput(defaultPostWindow);
    
    % Get unit type selection
    while true
        unitType = input('Select unit type (1: Single, 2: Multi, 3: Both): ', 's');
        switch unitType
            case '1'
                params.unitFilter = 'single';
                break;
            case '2'
                params.unitFilter = 'multi';
                break;
            case '3'
                params.unitFilter = 'both';
                break;
            otherwise
                fprintf('Invalid selection. Please enter 1, 2, or 3.\n');
        end
    end
    
    params.analysisStartTime = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss');
end


%% Helper Functions
function paths = setupDirectoryStructure(projectDir, ~)
    % Add debug prints
    fprintf('\nSetting up directory structure...\n');
    fprintf('Project directory: %s\n', projectDir);
    
    % Create paths
    parentDir = fileparts(projectDir);
    paths.projectDir = projectDir;
    paths.frTreatmentDir = fullfile(parentDir, 'frTreatmentAnalysis');
    paths.dataFile = fullfile(projectDir, 'SpikeStuff', 'all_data.mat');
    paths.cellDataStructPath = fullfile(paths.frTreatmentDir, 'data', 'cellDataStruct.mat');
    paths.figureFolder = fullfile(paths.frTreatmentDir, 'figures');
    
    % Print paths before creating directories
    fprintf('Paths to be created:\n');
    disp(paths);
    
    % Create directories with verification
    dirs = {paths.frTreatmentDir, ...
           fullfile(paths.frTreatmentDir, 'data'), ...
           paths.figureFolder};
    
    for i = 1:length(dirs)
        if ~isfolder(dirs{i})
            fprintf('Creating directory: %s\n', dirs{i});
            [success, msg] = mkdir(dirs{i});
            if ~success
                error('Failed to create directory: %s\nError: %s', dirs{i}, msg);
            end
        end
    end
end

% Save and Display Configuration Results
function saveConfiguration(params, paths)
    % Save in analysis directory with timestamp
    configFile = fullfile(paths.frTreatmentDir, ...
                         sprintf('analysisConfig_%s.mat', ...
                         char(params.analysisStartTime)));
    save(configFile, 'params', 'paths');
    
    % Also save as current config
    currentConfigFile = fullfile(paths.frTreatmentDir, 'currentConfig.mat');
    save(currentConfigFile, 'params', 'paths');
    
    fprintf('Configuration saved to:\n%s\n', configFile);
end

function [params, paths] = loadConfiguration(configFile)
    if isfile(configFile)
        loaded = load(configFile);
        params = loaded.params;
        paths = loaded.paths;
    else
        error('Configuration file not found: %s', configFile);
    end
end

function displayConfiguration(params, paths)
    fprintf('\n=== Analysis Configuration Summary ===\n\n');
    
    % Display Analysis Parameters
    fprintf('Analysis Parameters:\n');
    fprintf('-------------------\n');
    fprintf('  Bin Width: %.1f seconds\n', params.binWidth);
    fprintf('  Box Car Window: %d seconds\n', params.boxCarWindow);
    fprintf('  Treatment Time: %d seconds\n', params.treatmentTime);
    fprintf('  Recording Period: %d seconds\n', params.recordingPeriod);
    fprintf('  Unit Filter: %s\n', params.unitFilter);
    fprintf('  Start Time: %s\n\n', char(params.analysisStartTime));
    
    % Display Directory Structure
    fprintf('Directory Structure:\n');
    fprintf('-------------------\n');
    fprintf('  Project Directory: %s\n', paths.projectDir);
    fprintf('  Analysis Directory: %s\n', paths.frTreatmentDir);
    fprintf('  Data File: %s\n', paths.dataFile);
    fprintf('  Cell Data Structure: %s\n', paths.cellDataStructPath);
    fprintf('  Figure Directory: %s\n', paths.figureFolder);
    
    % Add separator for readability
    fprintf('\nConfiguration saved and ready for analysis.\n\n');
end

% Validate User Input
function value = getValidNumericInput(prompt, minValue)
    while true
        value = input(prompt);
        if isnumeric(value) && isscalar(value) && value > minValue
            break;
        else
            fprintf('Please enter a valid number greater than %g.\n', minValue);
        end
    end
end

% Validate Project Structure
function valid = validateProjectStructure(projectDir)
    % Verify required folders and files exist
    spikeStuffDir = fullfile(projectDir, 'SpikeStuff');
    allDataPath = fullfile(spikeStuffDir, 'all_data.mat');
    
    if ~isfolder(spikeStuffDir)
        error('Invalid project structure: Missing SpikeStuff folder');
    end
    if ~isfile(allDataPath)
        error('Invalid project structure: Missing all_data.mat');
    end
    valid = true;
end

% Validate Window Input
function window = getValidWindowInput(defaultWindow)
    while true
        input_str = input('', 's');
        if isempty(input_str)
            window = defaultWindow;
            break;
        else
            try
                window = str2num(input_str);
                if numel(window) == 2 && window(1) < window(2)
                    break;
                else
                    fprintf('Please enter two numbers where the first is less than the second.\n');
                end
            catch
                fprintf('Invalid input. Please enter two numbers or press Enter for default.\n');
            end
        end
    end
end