function [params, paths] = initializeAnalysis()
    fprintf('\n=== Firing Rate Analysis Initialization ===\n\n');
    
    % Get project directory from user
    projectDir = uigetdir('~/', 'Select Project Directory containing SpikeStuff folder');
    if projectDir == 0
        error('User cancelled directory selection');
    end
    
    % Verify SpikeStuff and all_data.mat exist
    spikeStuffDir = fullfile(projectDir, 'SpikeStuff');
    allDataPath = fullfile(spikeStuffDir, 'all_data.mat');
    
    if ~isfolder(spikeStuffDir) || ~isfile(allDataPath)
        error('Invalid project directory structure. Missing SpikeStuff folder or all_data.mat');
    end
    
    % Get analysis parameters
    params = getAnalysisParams();
    
    % Create frTreatment directory structure
    paths = createDirectoryStructure(projectDir, params);
    
    % Save configuration
    saveConfiguration(params, paths);
    
    % Display summary
    displayConfiguration(params, paths);
end

function params = getAnalysisParams()
    fprintf('Setting Analysis Parameters:\n');
    fprintf('----------------------------\n');
    
    params.binWidth = getValidNumericInput('Enter bin width (seconds): ', 0);
    params.boxCarWindow = getValidNumericInput('Enter smoothing window size (seconds): ', 0);
    params.treatmentTime = getValidNumericInput('Enter treatment time (seconds): ', 0);
    params.recordingPeriod = getValidNumericInput('Enter total recording period (seconds): ', params.treatmentTime);
    
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

function paths = createDirectoryStructure(projectDir, params)
    % Create frTreatment directory at same level as SpikeStuff
    parentDir = fileparts(projectDir);
    frTreatmentDir = fullfile(parentDir, 'frTreatmentAnalysis');
    
    % Create main directories
    if ~isfolder(frTreatmentDir)
        mkdir(frTreatmentDir);
    end
    
    % Set up paths structure
    paths = struct();
    paths.projectDir = projectDir;
    paths.frTreatmentDir = frTreatmentDir;
    paths.dataFile = fullfile(projectDir, 'SpikeStuff', 'all_data.mat');
    paths.cellDataStructPath = fullfile(frTreatmentDir, 'cellDataStruct.mat');
    paths.figureFolder = fullfile(frTreatmentDir, 'figures');
    
    % Create figure directory
    if ~isfolder(paths.figureFolder)
        mkdir(paths.figureFolder);
    end
end

function saveConfiguration(params, paths)
    % Save configuration file in frTreatment directory
    configFile = fullfile(paths.frTreatmentDir, ...
                         sprintf('analysisConfig_%s.mat', ...
                         char(params.analysisStartTime)));
    
    config = struct('params', params, 'paths', paths);
    save(configFile, 'config');
    
    % Make parameters globally accessible
    global analysisParams
    analysisParams = params;
end

function displayConfiguration(params, paths)
    fprintf('\n=== Analysis Configuration Summary ===\n');
    fprintf('Analysis Parameters:\n');
    fprintf('  Bin Width: %.1f seconds\n', params.binWidth);
    fprintf('  Box Car Window: %d seconds\n', params.boxCarWindow);
    fprintf('  Treatment Time: %d seconds\n', params.treatmentTime);
    fprintf('  Recording Period: %d seconds\n', params.recordingPeriod);
    fprintf('  Unit Filter: %s\n', params.unitFilter);
    fprintf('  Start Time: %s\n\n', char(params.analysisStartTime));
    
    fprintf('Directory Structure:\n');
    fprintf('  Project Directory: %s\n', paths.projectDir);
    fprintf('  Analysis Directory: %s\n', paths.frTreatmentDir);
    fprintf('  Data File: %s\n', paths.dataFile);
    fprintf('  Cell Data Structure: %s\n', paths.cellDataStructPath);
    fprintf('  Figure Folder: %s\n\n', paths.figureFolder);
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
