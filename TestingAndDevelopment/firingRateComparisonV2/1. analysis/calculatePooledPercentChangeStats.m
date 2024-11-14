function [expStats, ctrlStats] = calculatePooledPercentChangeStats(cellDataStruct, treatmentTime, unitFilter, outlierFilter)
    % Set defaults
    if nargin < 4, outlierFilter = true; end
    if nargin < 3, unitFilter = 'both'; end
    if nargin < 2, treatmentTime = 1860; end
    
    % Initialize data structures
    expData = initializeDataStructure();
    ctrlData = initializeDataStructure();
    
    % Process experimental groups (Emx, Pvalb)
    expData = processExperimentalGroups(cellDataStruct, {'Emx', 'Pvalb'}, ...
                                      treatmentTime, unitFilter, outlierFilter);
    
    % Process control group
    if isfield(cellDataStruct, 'Control')
        ctrlData = processExperimentalGroups(cellDataStruct, {'Control'}, ...
                                           treatmentTime, unitFilter, outlierFilter);
    end
    
    % Calculate statistics
    expStats = calculateGroupStats(expData);
    ctrlStats = calculateGroupStats(ctrlData);
end

function groupStats = calculateGroupStats(data)
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    groupStats = struct();
    
    for rt = responseTypes
        responseType = rt{1};
        if isfield(data, responseType) && ~isempty(data.(responseType).baseline)
            [stats, testResults] = calculateStatistics(data.(responseType).baseline, ...
                                                     data.(responseType).post);
            groupStats.(responseType) = struct(...
                'data', data.(responseType), ...
                'stats', stats, ...
                'testResults', testResults);
        end
    end
end


function [stats, testResults] = calculateStatistics(baseline, post)
    % Calculate comprehensive statistics
    stats = struct();
    
    % Basic statistics for baseline
    stats.baseline = struct(...
        'mean', mean(baseline, 'omitnan'), ...
        'median', median(baseline, 'omitnan'), ...
        'std', std(baseline, 'omitnan'), ...
        'sem', std(baseline, 'omitnan')/sqrt(sum(~isnan(baseline))), ...
        'range', [min(baseline), max(baseline)], ...
        'n', sum(~isnan(baseline)));
    
    % Basic statistics for post
    stats.post = struct(...
        'mean', mean(post, 'omitnan'), ...
        'median', median(post, 'omitnan'), ...
        'std', std(post, 'omitnan'), ...
        'sem', std(post, 'omitnan')/sqrt(sum(~isnan(post))), ...
        'range', [min(post), max(post)], ...
        'n', sum(~isnan(post)));
    
    % Confidence Intervals (95%)
    stats.baseline.CI = [stats.baseline.mean - 1.96*stats.baseline.sem, ...
                        stats.baseline.mean + 1.96*stats.baseline.sem];
    stats.post.CI = [stats.post.mean - 1.96*stats.post.sem, ...
                    stats.post.mean + 1.96*stats.post.sem];
    
    % Statistical tests
    testResults = struct();
    
    % Paired t-test
    [~, testResults.ttest_p, ~, tstats] = ttest2(baseline, post);
    testResults.ttest_stats = tstats;
    
    % Wilcoxon signed rank test (non-parametric)
    [p_wilcox, h_wilcox, stats_wilcox] = signrank(baseline, post);
    testResults.wilcoxon = struct(...
        'p', p_wilcox, ...
        'h', h_wilcox, ...
        'stats', stats_wilcox);
    
    % Effect size (Cohen's d)
    pooled_std = sqrt((stats.baseline.std^2 + stats.post.std^2)/2);
    testResults.cohens_d = (stats.post.mean - stats.baseline.mean)/pooled_std;
end
