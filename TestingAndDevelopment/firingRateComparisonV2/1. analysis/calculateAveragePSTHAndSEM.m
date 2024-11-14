function [expPSTH, ctrlPSTH, normPSTH] = calculateAveragePSTHAndSEM(cellDataStruct, dataFolder, unitFilter, outlierFilter)
    % Set defaults
    if nargin < 4, outlierFilter = true; end
    if nargin < 3, unitFilter = 'both'; end
    
    % Initialize structures
    expPSTH = struct('mean', [], 'sem', [], 'timeVector', []);
    ctrlPSTH = struct('mean', [], 'sem', [], 'timeVector', []);
    normPSTH = struct('mean', [], 'sem', [], 'timeVector', []);
    
    % Get PSTH length and time vector from first valid unit
    [psthLength, timeVector] = getPSTHInfo(cellDataStruct);
    if psthLength == 0
        error('No valid units found for PSTH calculation');
    end
    
    % Calculate experimental PSTH (Emx and Pvalb)
    expPSTHs = collectPSTHs(cellDataStruct, {'Emx', 'Pvalb'}, psthLength, unitFilter, outlierFilter);
    expPSTH.mean = mean(expPSTHs, 1, 'omitnan');
    expPSTH.sem = std(expPSTHs, 0, 1, 'omitnan') / sqrt(size(expPSTHs, 1));
    expPSTH.timeVector = timeVector;
    expPSTH.n = size(expPSTHs, 1);
    
    % Calculate control PSTH
    if isfield(cellDataStruct, 'Control')
        ctrlPSTHs = collectPSTHs(cellDataStruct, {'Control'}, psthLength, unitFilter, outlierFilter);
        ctrlPSTH.mean = mean(ctrlPSTHs, 1, 'omitnan');
        ctrlPSTH.sem = std(ctrlPSTHs, 0, 1, 'omitnan') / sqrt(size(ctrlPSTHs, 1));
        ctrlPSTH.timeVector = timeVector;
        ctrlPSTH.n = size(ctrlPSTHs, 1);
        
        % Calculate normalized PSTH (experimental/control)
        normPSTH.mean = expPSTH.mean ./ ctrlPSTH.mean;
        % Error propagation for division
        normPSTH.sem = normPSTH.mean .* sqrt((expPSTH.sem./expPSTH.mean).^2 + ...
                                            (ctrlPSTH.sem./ctrlPSTH.mean).^2);
        normPSTH.timeVector = timeVector;
    end
    
    % Save results
    if ~isempty(dataFolder)
        saveResults(expPSTH, ctrlPSTH, normPSTH, dataFolder);
    end
end

function [psthLength, timeVector] = getPSTHInfo(cellDataStruct)
    psthLength = 0;
    timeVector = [];
    
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        recordings = fieldnames(cellDataStruct.(groupNames{g}));
        for r = 1:length(recordings)
            units = fieldnames(cellDataStruct.(groupNames{g}).(recordings{r}));
            for u = 1:length(units)
                unitData = cellDataStruct.(groupNames{g}).(recordings{r}).(units{u});
                if isfield(unitData, 'psthSmoothed') && ~isempty(unitData.psthSmoothed)
                    psthLength = length(unitData.psthSmoothed);
                    timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
                    return;
                end
            end
        end
    end
end

function psths = collectPSTHs(cellDataStruct, groupNames, psthLength, unitFilter, outlierFilter)
    psths = [];
    
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        if ~isfield(cellDataStruct, groupName)
            continue;
        end
        
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitData = cellDataStruct.(groupName).(recordingName).(units{u});
                
                % Validate unit
                if ~isValidUnit(unitData, unitFilter, outlierFilter)
                    continue;
                end
                
                % Add PSTH to collection
                psths(end+1, :) = unitData.psthSmoothed;
            end
        end
    end
end

function isValid = isValidUnit(unitData, unitFilter, outlierFilter)
    % Check outlier status
    if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
        isValid = false;
        return;
    end
    
    % Check unit type
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    if strcmp(unitFilter, 'single') && ~isSingleUnit || ...
       strcmp(unitFilter, 'multi') && isSingleUnit
        isValid = false;
        return;
    end
    
    % Check required fields
    isValid = isfield(unitData, 'psthSmoothed') && ...
              isfield(unitData, 'binEdges') && ...
              isfield(unitData, 'binWidth');
end

function saveResults(expPSTH, ctrlPSTH, normPSTH, dataFolder)
    timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
    filename = sprintf('averagePSTHs_%s.mat', timestamp);
    
    % Create save directory if it doesn't exist
    saveDir = fullfile(dataFolder, '0. expFigures');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    
    % Save results
    save(fullfile(saveDir, filename), 'expPSTH', 'ctrlPSTH', 'normPSTH', '-v7.3');
    fprintf('Results saved to: %s\n', fullfile(saveDir, filename));
end

