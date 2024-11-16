function [params, paths] = initializeAnalysis()
    % Main initialization function that coordinates the setup process
    fprintf('\n=== Firing Rate Analysis Initialization ===\n\n');
    
    % Get project directory from user
    projectDir = getProjectDirectory();
    
    % Verify project structure
    validateProjectStructure(projectDir);
    
    % Get analysis parameters from user
    params = getAnalysisParams();
    
    % Create directory structure and set paths
    paths = setupDirectoryStructure(projectDir, params);
    
    % Save configuration
    saveConfiguration(params, paths);
    
    % Display summary
    displayConfiguration(params, paths);
end

function projectDir = getProjectDirectory()
    % Get and validate project directory
    projectDir = uigetdir('~/', 'Select Project Directory containing SpikeStuff folder');
    if projectDir == 0
        error('User cancelled directory selection');
    end
end

function validateProjectStructure(projectDir)
    % Verify required folders and files exist
    spikeStuffDir = fullfile(projectDir, 'SpikeStuff');
    allDataPath = fullfile(spikeStuffDir, 'all_data.mat');
    
    if ~isfolder(spikeStuffDir)
        error('Invalid project structure: Missing SpikeStuff folder');
    end
    if ~isfile(allDataPath)
        error('Invalid project structure: Missing all_data.mat');
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

function paths = setupDirectoryStructure(projectDir, params)
    % Create analysis directories and set paths
    parentDir = fileparts(projectDir);
    paths.projectDir = projectDir;
    paths.frTreatmentDir = fullfile(parentDir, 'frTreatmentAnalysis');
    paths.dataFile = fullfile(projectDir, 'SpikeStuff', 'all_data.mat');
    paths.cellDataStructPath = fullfile(paths.frTreatmentDir, 'data', 'cellDataStruct.mat');
    paths.figureFolder = fullfile(paths.frTreatmentDir, 'figures');
    
    % Create directories
    if ~isfolder(paths.frTreatmentDir)
        mkdir(paths.frTreatmentDir);
    end
    if ~isfolder(fullfile(paths.frTreatmentDir, 'data'))
        mkdir(fullfile(paths.frTreatmentDir, 'data'));
    end
    if ~isfolder(paths.figureFolder)
        mkdir(paths.figureFolder);
    end
end

function saveConfiguration(params, paths)
    % Save configuration file
    configFile = fullfile(paths.frTreatmentDir, ...
                         sprintf('analysisConfig_%s.mat', ...
                         char(params.analysisStartTime)));
    
    config = struct('params', params, 'paths', paths);
    save(configFile, 'config');
    
    % Make parameters globally accessible
    global analysisParams
    analysisParams = params;
end

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
