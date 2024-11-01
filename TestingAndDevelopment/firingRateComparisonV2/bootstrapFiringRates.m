function [pValue, responseType, bootResults] = bootstrapFiringRates(cellDataStruct, treatmentTime, preWindow, postWindow, numBootstrap, numTrials, param)
    % bootstrapFiringRateComparison: Compares firing rates pre- and post-treatment for two units using hierarchical bootstrapping.
    %
    % Inputs:
    %   - unit1Data, unit2Data: Structures containing PSTH data for two units.
    %   - treatmentTime: Time in seconds when treatment was administered.
    %   - preWindow, postWindow: Duration in seconds for pre- and post-treatment windows.
    %   - numBootstrap: Number of bootstrap samples.
    %   - numTrials: Number of resamples for each bootstrap iteration.
    %   - param: Statistic to calculate ('mean' or 'median').
    %
    % Outputs:
    %   - pValue: Bootstrap p-value for post-treatment >= pre-treatment.
    %   - responseType: Label indicating 'Increased', 'Decreased', or 'Unchanged'.
    %   - bootResults: Struct containing the bootstrapped distributions and summary statistics.
    
    % Set defaults if necessary
    if nargin < 3 || isempty(treatmentTime), treatmentTime = 1860; end
    if nargin < 4 || isempty(preWindow), preWindow = 1000; end
    if nargin < 5 || isempty(postWindow), postWindow = 3000; end
    if nargin < 6 || isempty(numBootstrap), numBootstrap = 10000; end
    if nargin < 7 || isempty(numTrials), numTrials = 50; end
    if nargin < 8 || isempty(param), param = 'mean'; end

    % Select Units for analysis
    

    % Extract PSTH data and bin width for both units
    binWidth = unit1Data.binWidth;  % Assume both units have the same bin width
    timeVector = (0:numel(unit1Data.psthSmoothed) - 1) * binWidth;

    % Define pre- and post-treatment indices
    preIndices = timeVector >= (treatmentTime - preWindow) & timeVector < treatmentTime;
    postIndices = timeVector >= treatmentTime & timeVector < (treatmentTime + postWindow);

    % Extract pre- and post-treatment data for both units
    preData1 = unit1Data.psthSmoothed(preIndices);
    postData1 = unit1Data.psthSmoothed(postIndices);
    preData2 = unit2Data.psthSmoothed(preIndices);
    postData2 = unit2Data.psthSmoothed(postIndices);

    % Perform hierarchical bootstrapping for pre- and post-treatment data
    [bootPre, bootPost] = hierarchicalBootstrapTwoUnits(preData1, postData1, preData2, postData2, numBootstrap, numTrials, param);

    % Calculate p-value and determine response type
    pValue = mean(bootPost >= bootPre);
    responseType = 'Unchanged';
    if pValue < 0.05
        if mean(bootPost) > mean(bootPre)
            responseType = 'Increased';
        else
            responseType = 'Decreased';
        end
    end

    % Package bootstrap results for output
    bootResults = struct('bootPre', bootPre, 'bootPost', bootPost, ...
                         'meanPre', mean(bootPre), 'meanPost', mean(bootPost), ...
                         'semPre', std(bootPre), 'semPost', std(bootPost), ...
                         'pValue', pValue, 'responseType', responseType);

    % Optional plot for sanity check
    figure;
    hold on;
    histogram(bootPre, 50, 'FaceColor', 'b', 'EdgeColor', 'k', 'DisplayName', 'Pre-Treatment');
    histogram(bootPost, 50, 'FaceColor', 'r', 'EdgeColor', 'k', 'DisplayName', 'Post-Treatment');
    title('Bootstrap Distributions: Pre- vs Post-Treatment');
    xlabel('Firing Rate');
    ylabel('Frequency');
    legend;
    hold off;
end

%% Helper Function: Hierarchical Bootstrapping for Two Units
function [bootPre, bootPost] = hierarchicalBootstrapTwoUnits(preData1, postData1, preData2, postData2, numBootstrap, numTrials, param)
    % hierarchicalBootstrapTwoUnits: Resamples at both unit and bin level to perform hierarchical bootstrapping.
    %
    % Outputs:
    %   - bootPre, bootPost: Bootstrap distributions for pre- and post-treatment.

    bootPre = NaN(numBootstrap, 1);
    bootPost = NaN(numBootstrap, 1);

    for i = 1:numBootstrap
        % Resample units at the first level
        sampledUnit = randi(2);  % Randomly select unit 1 or unit 2
        if sampledUnit == 1
            preBins = datasample(preData1, numTrials, 'Replace', true);
            postBins = datasample(postData1, numTrials, 'Replace', true);
        else
            preBins = datasample(preData2, numTrials, 'Replace', true);
            postBins = datasample(postData2, numTrials, 'Replace', true);
        end

        % Calculate the bootstrap statistic
        if strcmp(param, 'mean')
            bootPre(i) = mean(preBins);
            bootPost(i) = mean(postBins);
        elseif strcmp(param, 'median')
            bootPre(i) = median(preBins);
            bootPost(i) = median(postBins);
        else
            error('Unknown parameter. Use "mean" or "median".');
        end
    end
end
