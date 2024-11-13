function [cellDataStruct,sparseUnitsList] = tagSparseUnits(cellDataStruct, frBefore, binWidth, minFrRate)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Set default args
if nargin < 2 || isempty(minFrRate)
    minFrRate = 0.5; % set min fr rate to 0.5Hz
end

% Check if args present


% Set window for sampling
preTreatmentFr = frBefore;

% Normalize firing rate to bin width
preTreatmentFr = preTreatmentFr*binWidth;

% Loop through groups, recordings, and units
    % Loop through groups
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
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    % Label sparsity
                    if preTreatmentFr > minFrRate
                        unitData.isSparseUnit = 1;
                    else 
                        unitData.isSparseUnit = 0;
                    end
            end     
        end
    end % Saving logic not included; output goes to function w/ save block
end