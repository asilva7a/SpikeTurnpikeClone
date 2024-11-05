function calculatePercentChangePSTH(cellDataStruct, treatmentTime, preWindow, postWindow)
    % calculateAndSavePercentChangeStats: Calculates and saves percent change statistics for each unit.
    % The stats are saved under 'percentChangeStats' for each unit in cellDataStruct.
    %
    % Inputs:
    %   - cellDataStruct: Main data structure containing group, recording, and unit data.
    %   - treatmentTime: Time in seconds when treatment was administered.
    %   - preWindow: Duration in seconds for pre-treatment window.
    %   - postWindow: Duration in seconds for post-treatment window.
    %
    % Output:
    %   - cellDataStruct: Updated structure with percent change statistics saved for each unit.

    % Default treatment time and windows if not provided
    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 1860;
    end
    if nargin < 3 || isempty(preWindow)
        preWindow = 1000;
    end
    if nargin < 4 || isempty(postWindow)
        postWindow = 3000;
    end

    % Loop through each group, recording, and unit (cid) to calculate and save stats
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};

        % Check if groupName exists and is a structure
        if ~isstruct(cellDataStruct.(groupName))
            warning('Group %s is not a structure. Skipping...', groupName);
            continue;
        end

        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};

            % Check if recordingName exists and is a structure
            if ~isstruct(cellDataStruct.(groupName).(recordingName))
                warning('Recording %s in Group %s is not a structure. Skipping...', recordingName, groupName);
                continue;
            end

            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Check for required fields in unitData
                if isstruct(unitData) && isfield(unitData, 'psthSmoothed') && isfield(unitData, 'binEdges')
                    % Calculate percent change statistics for this unit
                    percentChangeStats = calculatePercentChangeStats(unitData, treatmentTime, preWindow, postWindow);

                    % Save the percentChangeStats struct to the unit data
                    cellDataStruct.(groupName).(recordingName).(unitID).percentChangeStats = percentChangeStats;

                    % Display confirmation message
                    fprintf('Calculated and saved percentChangeStats for Unit %s in %s - %s.\n', ...
                        unitID, groupName, recordingName);
                else
                    warning('Skipping Unit %s in %s - %s: Missing required fields.', unitID, groupName, recordingName);
                end
            end
        end
    end
end

%% Helper function to calculate percent change stats for a single unit
function percentChangeStats = calculatePercentChangeStats(unitData, treatmentTime, preWindow, postWindow)
    % Helper function to calculate percent change and descriptive statistics for a single unit.
    
    % Extract PSTH and bin edges
    psth = unitData.psthSmoothed;
    binEdges = unitData.binEdges;
    binWidth = binEdges(2) - binEdges(1);  % Calculate bin width from bin edges
    timeVector = binEdges(1:end-1) + binWidth / 2;  % Centered time for each bin
    
    % Define indices for pre- and post-treatment windows
    preIndices = (timeVector >= (treatmentTime - preWindow)) & (timeVector < treatmentTime);
    postIndices = (timeVector >= treatmentTime) & (timeVector < (treatmentTime + postWindow));
    
    % Calculate mean, median, standard deviation, and variance of firing rates
    preMean = mean(psth(preIndices), 'omitnan');
    postMean = mean(psth(postIndices), 'omitnan');
    preMedian = median(psth(preIndices), 'omitnan');
    postMedian = median(psth(postIndices), 'omitnan');
    preStdDev = std(psth(preIndices), 'omitnan');
    postStdDev = std(psth(postIndices), 'omitnan');
    preVariance = var(psth(preIndices), 'omitnan');
    postVariance = var(psth(postIndices), 'omitnan');
    
    % Calculate percent change
    if preMean == 0
        warning('Pre-treatment mean firing rate is zero; percent change is set to NaN to avoid division by zero.');
        percentChange = NaN;
    else
        percentChange = ((postMean - preMean) / abs(preMean)) * 100;
    end
    
    % Calculate 95% Confidence Interval for the percent change (assuming normality)
    percentChangeStdErr = abs(percentChange) * sqrt((postStdDev^2 / postMean^2 + preStdDev^2 / preMean^2));
    ci95 = percentChange + [-1.96, 1.96] * percentChangeStdErr;

    % Compile all statistics into an output struct
    percentChangeStats = struct( ...
        'preMean', preMean, ...
        'postMean', postMean, ...
        'preMedian', preMedian, ...
        'postMedian', postMedian, ...
        'preStdDev', preStdDev, ...
        'postStdDev', postStdDev, ...
        'preVariance', preVariance, ...
        'postVariance', postVariance, ...
        'percentChange', percentChange, ...
        'percentChangeCI95', ci95);
end
