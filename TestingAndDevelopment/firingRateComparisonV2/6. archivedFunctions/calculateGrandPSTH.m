function [grandAveragePSTH, timeVector] = calculateGrandPSTH(cellDataStruct)
% calculateGrandPSTH: Computes the grand average PSTH and corresponding time vector 
%                     across all units in the given cellDataStruct.
%
%   Dependencies:
%       * This function is designed for use within higher-level plotting functions, 
%         such as subPlotAllPSTHsRawWithMean, which use the average PSTH to represent 
%         overall unit activity across all groups and recordings.
%
%   Inputs:
%       - cellDataStruct: Struct containing smoothed PSTH data for multiple units.
%                         Each unit should have fields 'psthSmoothed' and 'binEdges'.
%
%   Outputs:
%       - grandAveragePSTH: Grand average of all smoothed PSTHs from individual units.
%       - timeVector: Time vector corresponding to the bin centers of the PSTH.
%
%   Purpose: Provides an average PSTH across all units in the structure, allowing for 
%            a single, representative PSTH plot in overarching functions.


%% Collect Data
    % Determine total units and PSTH length
    totalUnits = 0;
    psthLength = 0;
    groupNames = fieldnames(cellDataStruct);

    fprintf('Starting grand PSTH calculation.\n'); % Debugging statement
    
    % Loop to count units and determine PSTH length
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        fprintf('Processing group: %s\n', groupName); % Debugging statement
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            fprintf('  Processing recording: %s\n', recordingName); % Debugging statement
            
            for u = 1:length(units)
                unitID = units{u};
                
                try
                    % Check for 'psthSmoothed' field to ensure it exists
                    if isfield(cellDataStruct.(groupName).(recordingName).(unitID), 'psthSmoothed')
                        % Increment unit count
                        totalUnits = totalUnits + 1;

                        % Get PSTH length from the first valid unit
                        if psthLength == 0
                            psthLength = length(cellDataStruct.(groupName).(recordingName).(unitID).psthSmoothed);
                            fprintf('    Initial PSTH length determined: %d bins\n', psthLength); % Debugging statement
                        end
                    else
                        fprintf('    Warning: Unit %s in recording %s has no psthSmoothed field. Skipping...\n', unitID, recordingName);
                    end
                catch ME
                    fprintf('    Error accessing psthSmoothed for unit %s in recording %s: %s\n', unitID, recordingName, ME.message);
                end
            end
        end
    end

    % Preallocate the allPSTHs array with NaNs
    allPSTHs = NaN(totalUnits, psthLength);
    timeVector = [];  % Initialize for later
    unitIndex = 1;  % Index to keep track of row in allPSTHs

    % Populate allPSTHs array with each unit's PSTH
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};

                try
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                    % Check if 'psthSmoothed' field is available
                    if isfield(unitData, 'psthSmoothed')
                        psth = unitData.psthSmoothed;

                        % Set time vector if not already set
                        if isempty(timeVector) && isfield(unitData, 'binEdges')
                            binWidth = unitData.binWidth;
                            binEdges = unitData.binEdges;
                            timeVector = binEdges(1:end-1) + binWidth / 2;
                        end

                        % Store PSTH in the preallocated array
                        allPSTHs(unitIndex, :) = psth;
                        unitIndex = unitIndex + 1;

                        % Debugging message for each unit processed
                        fprintf('      Stored PSTH for unit %s in recording %s\n', unitID, recordingName);
                    else
                        fprintf('      Skipping unit %s: psthSmoothed field is missing.\n', unitID);
                    end
                catch ME
                    fprintf('    Error processing PSTH for unit %s in recording %s: %s\n', unitID, recordingName, ME.message);
                end
            end
        end
    end

    %% Calculate grand average
    % Calculate the overall average PSTH, ignoring NaNs
    try
        grandAveragePSTH = mean(allPSTHs, 1, 'omitnan');
        fprintf('Calculated overall average PSTH across %d units.\n', totalUnits);
    catch ME
        fprintf('Error calculating overall average PSTH: %s\n', ME.message);
        grandAveragePSTH = [];
    end
end

