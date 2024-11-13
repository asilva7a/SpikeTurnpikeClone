function [cellDataStruct, sparseUnitsList] = tagSparseUnits(cellDataStruct, frBefore, binWidth, minFrRate, projectData)
%tagSparseUnits Tags units with firing rates below threshold
%   Inputs:
%       cellDataStruct: Nested structure containing unit data
%       frBefore: Firing rates before treatment
%       binWidth: Width of time bins in seconds
%       minFrRate: Minimum firing rate threshold (default 0.5 Hz)
%       projectData: Optional path for saving results
%   Outputs:
%       cellDataStruct: Updated structure with sparse unit tags
%       sparseUnitsList: Table containing sparse unit information

% Set default args
if nargin < 4 || isempty(minFrRate)
    minFrRate = 0.5; % set min fr rate to 0.5Hz
end

% Get total number of units for table initialization
numFields = 0;
groupNames = fieldnames(cellDataStruct);
for g = 1:length(groupNames)
    recordings = fieldnames(cellDataStruct.(groupNames{g}));
    for r = 1:length(recordings)
        units = fieldnames(cellDataStruct.(groupNames{g}).(recordings{r}));
        numFields = numFields + length(units);
    end
end

% Initiate data table
unitTable = table('Size', [numFields, 4], ...
                  'VariableTypes', {'string', 'string', 'string', ...
                                    'double'}, ...
                  'VariableNames', {'unitID', 'recordingName', 'groupName', ...
                                    'sparseScore'});

% Set window for sampling
preTreatmentFr = frBefore;

% Normalize firing rate to bin width
preTreatmentFr = preTreatmentFr*binWidth;

% Initialize counter for table rows
rowCounter = 1;

% Loop through groups, recordings, and units
groupNames = fieldnames(cellDataStruct);
for g = 1:length(groupNames)
    groupName = groupNames{g};
    recordings = fieldnames(cellDataStruct.(groupName));
    % Loop through recordings
    for r = 1:length(recordings)
        recordingName = recordings{r};
        units = fieldnames(cellDataStruct.(groupName).(recordingName));
        % Loop through units
        for u = 1:length(units)
            unitID = units{u};
            
            % Label sparsity
            if preTreatmentFr(rowCounter) <= minFrRate
                cellDataStruct.(groupName).(recordingName).(unitID).isSparseUnit = 1;
                sparseScore = preTreatmentFr(rowCounter)/minFrRate; % Normalized score
            else 
                cellDataStruct.(groupName).(recordingName).(unitID).isSparseUnit = 0;
                sparseScore = 1; % Normal firing rate
            end
            
            % Add unit to table
            unitTable.unitID(rowCounter) = string(unitID);
            unitTable.recordingName(rowCounter) = string(recordingName);
            unitTable.groupName(rowCounter) = string(groupName);
            unitTable.sparseScore(rowCounter) = sparseScore;
            
            rowCounter = rowCounter + 1;
        end     
    end
end

% Create output table of sparse units only
sparseUnitsList = unitTable(unitTable.sparseScore < 1, :);

% Sort by sparseScore for easier analysis
sparseUnitsList = sortrows(sparseUnitsList, 'sparseScore', 'ascend');

% Optional: save sparseUnitList to projectData
if nargin > 4 && ~isempty(projectData)
    try
        % Create timestamp and filename
        timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
        fileName = sprintf('sparseUnitsTable_%s.csv', timeStamp);
        
        % Create save directory if it doesn't exist
        saveDir = fullfile(projectData, 'sparseUnitTable');
        if ~exist(saveDir, 'dir')
            mkdir(saveDir);
        end
        
        % Create full save path
        savePath = fullfile(saveDir, fileName);
        
        % Write table to CSV
        writetable(sparseUnitsList, savePath);
        
        fprintf('Successfully saved to %s\n', savePath);
        
    catch ME
        fprintf('Error saving sparse units table:\n');
        fprintf('Message: %s\n', ME.message);
        fprintf('Stack:\n');
        for k = 1:length(ME.stack)
            fprintf('File: %s, Line: %d, Function: %s\n', ...
                ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
        end
    end
end

end

