function cellDataStruct = calculatePercentChange(cellDataStruct, baselineWindow, treatmentTime, postWindow)
    % calculatePercentChange: Calculates percent change in firing rate for each unit's smoothed PSTH,
    % relative to a baseline period before treatment. Tracks metadata for both baseline and post-treatment periods.
    %
    % Inputs:
    %   - cellDataStruct: Main data structure containing all groups, recordings, and units.
    %   - baselineWindow: 2-element vector [start, end] for the baseline period in seconds.
    %   - treatmentTime: Scalar, indicating the treatment onset time in seconds.
    %   - postWindow: 2-element vector [start, end] for the post-treatment period in seconds.
    %
    % Output:
    %   - cellDataStruct: Updated structure with percent change values and metadata for each unit.

    % Load data
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\cellDataStruct_backup_2024-11-08_00-19-23.mat');
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\cellDataStructPath.mat');
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\dataFilePath.mat');
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\dataFolder.mat');
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\figureFolder.mat');

    % Default values for baselineWindow, treatmentTime, and postWindow if not provided
    if nargin < 2 || isempty(baselineWindow)
        baselineWindow = [0, 1800]; % Default baseline period
        fprintf('Default baselineWindow set to [%d, %d] seconds.\n', baselineWindow);
    end
    if nargin < 3 || isempty(treatmentTime)
        treatmentTime = 1860; % Default treatment onset time
        fprintf('Default treatmentTime set to %d seconds.\n', treatmentTime);
    end
    if nargin < 4 || isempty(postWindow)
        postWindow = [2000, 4000]; % Default post-treatment period
        fprintf('Default postWindow set to [%d, %d] seconds.\n', postWindow);
    end

    % Loop through each group, recording, and unit
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Check if unit is flagged as an outlier; skip if flagged
                if isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
                    continue;
                end

                % Ensure the unit has required fields: 'psthSmoothed' and time data
                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'binEdges') && isfield(unitData, 'binWidth')
                    psthSmoothed = unitData.psthSmoothed;
                    binEdges = unitData.binEdges;
                    binWidth = unitData.binWidth;
                    binCenters = binEdges(1:end-1) + binWidth / 2;

                    % Define baseline and post-treatment indices
                    baselineIndices = binCenters >= baselineWindow(1) & binCenters < baselineWindow(2);
                    postIndices = binCenters >= postWindow(1) & binCenters < postWindow(2);

                    % Calculate baseline average firing rate
                    baselineMean = mean(psthSmoothed(baselineIndices), 'omitnan');

                    % Calculate percent change relative to baseline for the entire PSTH
                    psthPercentChange = ((psthSmoothed - baselineMean) / baselineMean) * 100;

                    % Store percent change array in unit data
                    cellDataStruct.(groupName).(recordingName).(unitID).psthPercentChange = psthPercentChange;

                    % Compute and store metadata
                    psthPercentChangeStats = struct();
                    psthPercentChangeStats.baseline = struct( ...
                        'mean', baselineMean, ...
                        'stdDev', std(psthSmoothed(baselineIndices), 'omitnan'), ...
                        'range', range(psthSmoothed(baselineIndices)), ...
                        'var', var(psthSmoothed(baselineIndices)));

                    psthPercentChangeStats.postTreatment = struct( ...
                        'mean', mean(psthSmoothed(postIndices), 'omitnan'), ...
                        'stdDev', std(psthSmoothed(postIndices), 'omitnan'), ...
                        'range', range(psthSmoothed(postIndices)),...
                        'var', var(psthSmoothed(postIndices)));
    
                    % Store metadata struct in unit data
                    cellDataStruct.(groupName).(recordingName).(unitID).psthPercentChangeStats = psthPercentChangeStats;
                end
            end
        end
    end
end