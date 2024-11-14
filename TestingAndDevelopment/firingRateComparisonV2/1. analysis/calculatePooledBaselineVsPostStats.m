function [expStats, ctrlStats] = calculatePooledBaselineVsPostStats(cellDataStruct, treatmentTime, unitFilter, outlierFilter)
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

function dataStruct = initializeDataStructure()
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    dataStruct = struct();
    for rt = responseTypes
        dataStruct.(rt{1}) = struct(...
            'baseline', [], ...
            'post', []);
    end
end

function data = processExperimentalGroups(cellDataStruct, groupNames, treatmentTime, unitFilter, outlierFilter)
    data = initializeDataStructure();
    
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        if ~isfield(cellDataStruct, groupName)
            continue;
        end
        
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitData = cellDataStruct.(groupName).(recordingName).(units{u});
                
                % Validate unit
                if ~isValidUnit(unitData, unitFilter, outlierFilter)
                    continue;
                end
                
                % Get response type
                responseType = strrep(unitData.responseType, ' ', '');
                if ~isfield(data, responseType)
                    continue;
                end
                
                % Calculate time indices
                timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
                baselineIdx = timeVector < treatmentTime;
                postIdx = timeVector > treatmentTime;
                
                % Calculate mean firing rates
                baselineFR = mean(unitData.psthSmoothed(baselineIdx), 'omitnan');
                postFR = mean(unitData.psthSmoothed(postIdx), 'omitnan');
                
                % Store data
                data.(responseType).baseline(end+1) = baselineFR;
                data.(responseType).post(end+1) = postFR;
            end
        end
    end
end

function isValid = isValidUnit(unitData, unitFilter, outlierFilter)
    % Check outlier status
    if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
        isValid = false;
        return;
    end
    
    % Check unit type
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    if strcmp(unitFilter, 'single') && ~isSingleUnit || ...
       strcmp(unitFilter, 'multi') && isSingleUnit
        isValid = false;
        return;
    end
    
    % Check required fields
    isValid = isfield(unitData, 'psthSmoothed') && ...
              isfield(unitData, 'responseType') && ...
              isfield(unitData, 'binEdges') && ...
              isfield(unitData, 'binWidth');
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
