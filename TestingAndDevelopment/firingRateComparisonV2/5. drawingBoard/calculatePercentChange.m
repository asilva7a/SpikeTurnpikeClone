function calculatePercentChange(baselineWindow, treatmentTime, postWindow)
    % calculatePercentChange: Calculates percent change in firing rate for a specified unit's smoothed PSTH,
    % relative to a baseline period before treatment. Also tracks metadata for both baseline and post-treatment periods.
    %
    % Inputs:
    %   - unitData: Struct containing the specific unit's data (e.g., cellDataStruct.Emx.recording.cid311).
    %   - baselineWindow: 2-element vector [start, end] indicating time range for baseline calculation.
    %   - treatmentTime: Scalar value indicating the treatment time in seconds.
    %   - postWindow: 2-element vector [start, end] indicating time range for post-treatment period.
    %
    % Output:
    %   - unitData: Updated unit structure containing:
    %       - psthPercentChange: Array of percent change values for the entire PSTH.
    %       - psthPercentChangeStats: Sub-struct with metadata on baseline and post-treatment stats.

    % Load data
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\cellDataStruct_backup_2024-11-08_00-19-23.mat');
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\cellDataStructPath.mat');
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\dataFilePath.mat');
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\dataFolder.mat');
    load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\figureFolder.mat');

    % UnitID
    unitData = cellDataStruct.Emx.emx_hCTZtreated_0001_rec1.cid186;

    % Default baseline and post-treatment time windows if not provided
    if nargin < 1 || isempty(baselineWindow)
        baselineWindow = [0, 1800]; % Example baseline window
        fprintf('Default baselineWindow set to [%d, %d] seconds.\n', baselineWindow);
    end
    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 1860; % Example treatment time
        fprintf('Default treatmentTime set to %d seconds.\n', treatmentTime);
    end
    if nargin < 3 || isempty(postWindow)
        postWindow = [2000, 4000]; % Example post-treatment window
        fprintf('Default postWindow set to [%d, %d] seconds.\n', postWindow);
    end

    % Check if the unit was flagged as an outlier; if so, skip processing
    if isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
        fprintf('Unit is flagged as an outlier. Skipping calculation.\n');
        return;
    end

    % Ensure required fields are present
    if ~isfield(unitData, 'psthSmoothed') || ~isfield(unitData, 'binEdges') || ~isfield(unitData, 'binWidth')
        error('Unit data must contain "psthSmoothed", "binEdges", and "binWidth" fields.');
    end

    % Calculate bin centers for PSTH data
    binWidth = unitData.binWidth;
    binCenters = unitData.binEdges(1:end-1) + binWidth / 2;

    % Identify baseline and post-treatment period indices
    baselineIndices = binCenters >= baselineWindow(1) & binCenters <= baselineWindow(2);
    postIndices = binCenters >= postWindow(1) & binCenters <= postWindow(2);

    if ~any(baselineIndices)
        error('No data found in the specified baseline window.');
    end
    if ~any(postIndices)
        error('No data found in the specified post-treatment window.');
    end

    % Calculate baseline statistics
    baselineFiringRates = unitData.psthSmoothed(baselineIndices);
    baselineMean = mean(baselineFiringRates);
    baselineStd = std(baselineFiringRates);
    baselineRange = range(baselineFiringRates);
    baselineVar = var(baselineFiringRates);

    % Calculate post-treatment statistics
    postFiringRates = unitData.psthSmoothed(postIndices);
    postMean = mean(postFiringRates);
    postStd = std(postFiringRates);
    postRange = range(postFiringRates);
    postVar = var(postFiringRates);

    % Calculate percent change for the entire PSTH relative to baseline mean
    psthPercentChange = ((unitData.psthSmoothed - baselineMean) / baselineMean) * 100;

    % Store percent change and baseline/post-treatment metadata in the unit structure
    unitData.psthPercentChange = psthPercentChange;
    unitData.psthPercentChangeStats = struct( ...
        'BaselineMean', baselineMean, ...
        'BaselineStd', baselineStd, ...
        'BaselineRange', baselineRange, ...
        'BaselineVar', baselineVar, ...
        'PostMean', postMean, ...
        'PostStd', postStd, ...
        'PostRange', postRange, ...
        'PostVar', postVar ...
    );

    fprintf('Percent change calculated and stored.\n');
end
