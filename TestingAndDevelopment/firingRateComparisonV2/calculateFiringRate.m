function [cellDataStruct] = calculateFiringRate(cellDataStruct, treatmentTime, preWindow, postWindow, plotFlag)
    % calculateAndPlotFiringRateStats: Calculates firing rate statistics before and after treatment
    % and generates ladder plots to visualize results if plotFlag is true.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing the smoothed PSTH data.
    %   - treatmentTime: The time in seconds when luciferin was administered.
    %   - preWindow: Duration in seconds to consider before treatment.
    %   - postWindow: Duration in seconds to consider after treatment.
    %   - plotFlag: Boolean to enable/disable plotting (default is true).

    % Default values for treatment time, window sizes, and plot flag
    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 1860; % Default treatment time in seconds
        disp('No treatment time specified; defaulting to 1860 seconds.');
    end
    if nargin < 3 || isempty(preWindow)
        preWindow = 1000;  % Default pre-treatment window in seconds
        disp('No pre-treatment window specified; defaulting to 1000 seconds.');
    end
    if nargin < 4 || isempty(postWindow)
        postWindow = 3000;  % Default post-treatment window in seconds
        disp('No post-treatment window specified; defaulting to 3000 seconds.');
    end
    if nargin < 5
        plotFlag = true;  % Default to plot if plotFlag is not specified
        disp('No plot flag specified; defaulting to plotting enabled.');
    end

    % Loop to determine the total number of units for preallocation
    totalUnits = 0;
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        recordings = fieldnames(cellDataStruct.(groupNames{g}));
        for r = 1:length(recordings)
            units = fieldnames(cellDataStruct.(groupNames{g}).(recordings{r}));
            totalUnits = totalUnits + numel(units);
        end
    end

    % Preallocate arrays to store pre- and post-treatment statistics for all units
    preRates = NaN(totalUnits, 1);
    postRates = NaN(totalUnits, 1);
    preVariances = NaN(totalUnits, 1);
    postVariances = NaN(totalUnits, 1);
    preStdDevs = NaN(totalUnits, 1);
    postStdDevs = NaN(totalUnits, 1);
    preSpikeCounts = NaN(totalUnits, 1);
    postSpikeCounts = NaN(totalUnits, 1);

    % Initialize counter for indexing the preallocated arrays
    unitIndex = 0;

    % Main loop over groups, recordings, and units to calculate statistics
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                try
                    % Extract unit data
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    fprintf('Processing: Group: %s | Recording: %s | Unit: %s\n', groupName, recordingName, unitID);

                    % Check for necessary fields
                    if ~isfield(unitData, 'psthSmoothed') || ~isfield(unitData, 'binWidth')
                        warning('Skipping Unit %s: Missing psthSmoothed or binWidth.', unitID);
                        continue;
                    end

                    % Increment unit index for each unit
                    unitIndex = unitIndex + 1;

                    % Load PSTH data and bin width
                    psthData = unitData.psthSmoothed;
                    binWidth = unitData.binWidth;

                    % Calculate time vector for PSTH data based on bin width
                    numBins = numel(psthData);
                    timeVector = (0:numBins - 1) * binWidth;

                    % Define pre- and post-treatment windows
                    preTreatmentStart = max(0, treatmentTime - preWindow);
                    preTreatmentEnd = treatmentTime;
                    postTreatmentStart = treatmentTime;
                    postTreatmentEnd = treatmentTime + postWindow;

                    % Find indices for pre- and post-treatment windows
                    preIndices = timeVector >= preTreatmentStart & timeVector < preTreatmentEnd;
                    postIndices = timeVector >= postTreatmentStart & timeVector < postTreatmentEnd;

                    % Calculate statistics for pre-treatment window
                    preTreatmentRate = mean(psthData(preIndices), 'omitnan');
                    preTreatmentVariance = var(psthData(preIndices), 'omitnan');
                    preTreatmentStdDev = std(psthData(preIndices), 'omitnan');
                    preTreatmentSpikeCount = sum(psthData(preIndices)) * binWidth;

                    % Calculate statistics for post-treatment window
                    postTreatmentRate = mean(psthData(postIndices), 'omitnan');
                    postTreatmentVariance = var(psthData(postIndices), 'omitnan');
                    postTreatmentStdDev = std(psthData(postIndices), 'omitnan');
                    postTreatmentSpikeCount = sum(psthData(postIndices)) * binWidth;

                    % Store calculated statistics in the preallocated arrays
                    preRates(unitIndex) = preTreatmentRate;
                    postRates(unitIndex) = postTreatmentRate;
                    preVariances(unitIndex) = preTreatmentVariance;
                    postVariances(unitIndex) = postTreatmentVariance;
                    preStdDevs(unitIndex) = preTreatmentStdDev;
                    postStdDevs(unitIndex) = postTreatmentStdDev;
                    preSpikeCounts(unitIndex) = preTreatmentSpikeCount;
                    postSpikeCounts(unitIndex) = postTreatmentSpikeCount;

                    % Store results in the cellDataStruct
                    cellDataStruct.(groupName).(recordingName).(unitID).frBaselineAvg = preTreatmentRate;
                    cellDataStruct.(groupName).(recordingName).(unitID).frBaselineVariance = preTreatmentVariance;
                    cellDataStruct.(groupName).(recordingName).(unitID).frBaselineStdDev = preTreatmentStdDev;
                    cellDataStruct.(groupName).(recordingName).(unitID).frBaselineSpikeCount = preTreatmentSpikeCount;

                    cellDataStruct.(groupName).(recordingName).(unitID).frTreatmentAvg = postTreatmentRate;
                    cellDataStruct.(groupName).(recordingName).(unitID).frTreatmentVariance = postTreatmentVariance;
                    cellDataStruct.(groupName).(recordingName).(unitID).frTreatmentStdDev = postTreatmentStdDev;
                    cellDataStruct.(groupName).(recordingName).(unitID).frTreatmentSpikeCount = postTreatmentSpikeCount;

                catch ME
                    fprintf('Error processing unit %s in %s/%s: %s\n', unitID, groupName, recordingName, ME.message);
                end
            end
        end
    end

    % Generate ladder plots if plotFlag is true
    if plotFlag
        try
            figure('Name', sprintf('Group: %s - Pre vs Post Treatment', groupName), 'NumberTitle', 'off');
            subplot(2, 2, 1);
            ladderPlot(preRates, postRates, 'Firing Rate (spikes/s)');

            subplot(2, 2, 2);
            ladderPlot(preVariances, postVariances, 'Variance');

            subplot(2, 2, 3);
            ladderPlot(preStdDevs, postStdDevs, 'Standard Deviation');

            subplot(2, 2, 4);
            ladderPlot(preSpikeCounts, postSpikeCounts, 'Spike Count');
        catch ME
            fprintf('Error generating plots: %s\n', ME.message);
        end
    end
end

%% Helper function for creating ladder plots
function ladderPlot(preValues, postValues, yLabelText)
    % Ladder plot for comparing pre- and post-treatment values
    hold on;
    for i = 1:length(preValues)
        plot([1, 2], [preValues(i), postValues(i)], '-o', 'MarkerSize', 6, 'LineWidth', 1.2);
    end
    xlim([0.8, 2.2]);
    xticks([1, 2]);
    xticklabels({'Pre', 'Post'});
    ylabel(yLabelText);
    title(['Pre vs Post ', yLabelText]);
    grid on;
end
