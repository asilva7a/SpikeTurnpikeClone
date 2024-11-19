function [expStats, ctrlStats] = calculatePooledBaselineVsPostStats(cellDataStruct, treatmentTime, unitFilter, outlierFilter)
    % Set defaults
    if nargin < 4, outlierFilter = true; end
    if nargin < 3, unitFilter = 'both'; end
    if nargin < 2, treatmentTime = 1860; end
    
    % Initialize counters
    totalUnits = struct('Increased', 0, 'Decreased', 0, 'No_Change', 0);
    excludedUnits = struct('Outlier', 0, 'UnitType', 0, 'MissingFields', 0);
    
    fprintf('\nDebugging Unit Selection:\n');
    fprintf('------------------------\n');
    
    % Initialize data structures
    expData = initializeDataStructure();
    ctrlData = initializeDataStructure();
    
    % Process experimental groups (Emx, Pvalb)
    [expData, totalUnits, excludedUnits] = processExperimentalGroups(cellDataStruct, {'Emx', 'Pvalb'}, ...
        treatmentTime, unitFilter, outlierFilter, totalUnits, excludedUnits);
    
    % Process control group
    if isfield(cellDataStruct, 'Control')
        [ctrlData, totalUnits, excludedUnits] = processExperimentalGroups(cellDataStruct, {'Control'}, ...
            treatmentTime, unitFilter, outlierFilter, totalUnits, excludedUnits);
    end
    
    % Print summary
    fprintf('\nUnit Selection Summary:\n');
    fprintf('--------------------\n');
    fprintf('Total Increased units found: %d\n', totalUnits.Increased);
    fprintf('Total Decreased units found: %d\n', totalUnits.Decreased);
    fprintf('Total No Change units found: %d\n', totalUnits.No_Change);
    fprintf('\nExcluded Units:\n');
    fprintf('Outliers: %d\n', excludedUnits.Outlier);
    fprintf('Wrong unit type: %d\n', excludedUnits.UnitType);
    fprintf('Missing fields: %d\n', excludedUnits.MissingFields);
    
    % Calculate statistics
    expStats = calculateGroupStats(expData);
    ctrlStats = calculateGroupStats(ctrlData);
end

function dataStruct = initializeDataStructure()
    responseTypes = {'Increased', 'Decreased', 'No_Change'};
    dataStruct = struct();
    for rt = responseTypes
        dataStruct.(rt{1}) = struct(...
            'baseline', [], ...
            'post', []);
    end
end

function [data, totalUnits, excludedUnits] = processExperimentalGroups(cellDataStruct, groupNames, treatmentTime, unitFilter, outlierFilter, totalUnits, excludedUnits)
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
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                fprintf('Checking %s/%s/%s: ', groupName, recordingName, unitID);
                
                % Check outlier status
                if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
                    fprintf('Excluded (Outlier)\n');
                    excludedUnits.Outlier = excludedUnits.Outlier + 1;
                    continue;
                end
                
                % Check unit type
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if strcmp(unitFilter, 'single') && ~isSingleUnit || ...
                   strcmp(unitFilter, 'multi') && isSingleUnit
                    fprintf('Excluded (Wrong unit type)\n');
                    excludedUnits.UnitType = excludedUnits.UnitType + 1;
                    continue;
                end
                
                % Check required fields
                if ~isfield(unitData, 'psthSmoothed') || ...
                   ~isfield(unitData, 'responseType') || ...
                   ~isfield(unitData, 'binEdges') || ...
                   ~isfield(unitData, 'binWidth')
                    fprintf('Excluded (Missing fields)\n');
                    excludedUnits.MissingFields = excludedUnits.MissingFields + 1;
                    continue;
                end
                
                % Get response type and increment counter
                responseType = strrep(unitData.responseType, ' ', '');
                if ~isfield(data, responseType)
                    fprintf('Excluded (Invalid response type: %s)\n', responseType);
                    continue;
                end
                
                % Update counters based on response type
                switch responseType
                    case 'Increased'
                        totalUnits.Increased = totalUnits.Increased + 1;
                    case 'Decreased'
                        totalUnits.Decreased = totalUnits.Decreased + 1;
                    case 'No_Change'
                        totalUnits.No_Change = totalUnits.No_Change + 1;
                end
                
                fprintf('Included (%s)\n', responseType);
                
                % Calculate and store data
                timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
                baselineIdx = timeVector < treatmentTime;
                postIdx = timeVector > treatmentTime;
                
                baselineFR = mean(unitData.psthSmoothed(baselineIdx), 'omitnan');
                postFR = mean(unitData.psthSmoothed(postIdx), 'omitnan');
                
                data.(responseType).baseline(end+1) = baselineFR;
                data.(responseType).post(end+1) = postFR;
            end
        end
    end
end

function groupStats = calculateGroupStats(data)
    responseTypes = {'Increased', 'Decreased', 'No_Change'};
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