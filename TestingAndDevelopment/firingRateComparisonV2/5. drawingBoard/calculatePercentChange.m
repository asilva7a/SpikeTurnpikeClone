function unitData = calculatePercentChange(unitData, baselineWindow, treatmentTime, postWindow)
    % calculatePercentChange: Calculates percent change in firing rate for a unit's smoothed PSTH,
    % relative to a baseline period before treatment. Tracks metadata for both baseline and post-treatment periods.
    %
    % Inputs:
    %   - unitData: Data structure for an individual unit, containing fields 'psthSmoothed', 'binEdges',
    %               and 'isOutlierExperimental'.
    %   - baselineWindow: 2-element vector [start, end] indicating the time range for baseline calculation.
    %   - treatmentTime: Scalar value indicating the treatment time in seconds.
    %   - postWindow: 2-element vector [start, end] indicating the time range for post-treatment period.
    %
    % Output:
    %   - unitData: Updated unit structure containing:
    %       - psthPercentChange: Array of percent change values for the entire PSTH.
    %       - psthPercentChangeStats: Sub-struct with metadata on baseline and post-treatment stats:
    %           - BaselineMean, BaselineStd, BaselineRange, BaselineVar
    %           - PostMean, PostStd, PostRange, PostVar

    % Check if the unit was flagged as an outlier; if so, skip processing
    if isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
        fprintf('Unit %s is flagged as an outlier. Skipping calculation.\n', unitData.cid);
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

    fprintf('Percent change calculated and stored for unit %s.\n', unitData.cid);
end

