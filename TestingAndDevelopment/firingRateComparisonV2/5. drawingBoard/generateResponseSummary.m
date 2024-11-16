function generateResponseSummary(cellDataStruct, paths, params)
    % Parse input parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct', @isstruct);
    addRequired(p, 'paths', @isstruct);
    addRequired(p, 'params', @isstruct);
    addParameter(p, 'PlotFigures', true, @islogical);
    addParameter(p, 'SaveTable', true, @islogical);
    
    parse(p, cellDataStruct, paths, params);
    opts = p.Results;
    
    % Initialize counters and storage
    responseTypes = {'Strong_Increase', 'Moderate_Increase', 'Weak_Change', ...
                    'Moderate_Decrease', 'Strong_Decrease', 'Variable_Increase', ...
                    'Variable_Decrease', 'No_Change'};
    groupStats = struct();
    
    % Collect statistics
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Initialize counters for this group
        responseCounts = zeros(1, length(responseTypes));
        totalUnits = 0;
        allPValues = [];
        allEffectSizes = [];
        allReliability = [];
        
        % Process each recording
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                if isfield(unitData, 'responseType') && isfield(unitData, 'stats')
                    % Count response types
                    typeIdx = find(strcmp(responseTypes, unitData.responseType));
                    if ~isempty(typeIdx)
                        responseCounts(typeIdx) = responseCounts(typeIdx) + 1;
                    end
                    
                    % Collect statistics
                    if isfield(unitData.stats, 'p_value')
                        allPValues = [allPValues; unitData.stats.p_value];
                    end
                    if isfield(unitData.stats, 'cohens_d')
                        allEffectSizes = [allEffectSizes; unitData.stats.cohens_d];
                    end
                    if isfield(unitData.stats, 'reliability')
                        allReliability = [allReliability; unitData.stats.reliability];
                    end
                    
                    totalUnits = totalUnits + 1;
                end
            end
        end
        
        % Store group statistics
        groupStats.(groupName) = struct(...
            'responseCounts', responseCounts, ...
            'responsePercentages', (responseCounts/totalUnits)*100, ...
            'totalUnits', totalUnits, ...
            'meanPValue', mean(allPValues, 'omitnan'), ...
            'medianPValue', median(allPValues, 'omitnan'), ...
            'meanEffectSize', mean(allEffectSizes, 'omitnan'), ...
            'meanReliability', mean(allReliability, 'omitnan'));
    end
    
    % Generate summary table
    summaryTable = createSummaryTable(groupStats, responseTypes);
    
    % Save results
    if opts.SaveTable
        writetable(summaryTable, fullfile(paths.frTreatmentDir, 'data', ...
            sprintf('response_summary_%s.csv', char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm')))));
    end
    
    % Create visualizations
    if opts.PlotFigures
        createVisualization(groupStats, responseTypes, paths);
    end
end

function summaryTable = createSummaryTable(groupStats, responseTypes)
    % Initialize table variables
    groups = fieldnames(groupStats);
    numGroups = length(groups);
    
    % Create table arrays
    groupColumn = cell(numGroups * length(responseTypes), 1);
    responseTypeColumn = cell(numGroups * length(responseTypes), 1);
    countColumn = zeros(numGroups * length(responseTypes), 1);
    percentageColumn = zeros(numGroups * length(responseTypes), 1);
    
    % Fill table data
    idx = 1;
    for g = 1:numGroups
        groupName = groups{g};
        for r = 1:length(responseTypes)
            groupColumn{idx} = groupName;
            responseTypeColumn{idx} = responseTypes{r};
            countColumn(idx) = groupStats.(groupName).responseCounts(r);
            percentageColumn(idx) = groupStats.(groupName).responsePercentages(r);
            idx = idx + 1;
        end
    end
    
    % Create table
    summaryTable = table(groupColumn, responseTypeColumn, countColumn, percentageColumn, ...
        'VariableNames', {'Group', 'ResponseType', 'Count', 'Percentage'});
end

function createVisualization(groupStats, responseTypes, paths)
    % Create figure
    fig = figure('Position', [100 100 1200 800]);
    
    % Create subplots
    subplot(2,2,1) % Response type distribution
    plotResponseDistribution(groupStats, responseTypes);
    
    subplot(2,2,2) % Effect sizes
    plotEffectSizes(groupStats);
    
    subplot(2,2,3) % P-value distribution
    plotPValueDistribution(groupStats);
    
    subplot(2,2,4) % Reliability scores
    plotReliabilityScores(groupStats);
    
    % Save figure
    saveas(fig, fullfile(paths.frTreatmentDir, 'data', ...
        sprintf('response_summary_plots_%s.png', ...
        char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm')))));
    close(fig);
end

function plotResponseDistribution(groupStats, responseTypes)
    groups = fieldnames(groupStats);
    numGroups = length(groups);
    
    % Create grouped bar plot
    data = zeros(length(responseTypes), numGroups);
    for g = 1:numGroups
        data(:,g) = groupStats.(groups{g}).responsePercentages';
    end
    
    b = bar(data);
    title('Response Type Distribution');
    xlabel('Response Type');
    ylabel('Percentage of Units');
    legend(groups);
    xticks(1:length(responseTypes));
    xticklabels(responseTypes);
    xtickangle(45);
    
    % Add value labels
    for i = 1:length(b)
        for j = 1:size(data,1)
            text(j, data(j,i), sprintf('%.1f%%', data(j,i)), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom');
        end
    end
end

function plotEffectSizes(groupStats)
    groups = fieldnames(groupStats);
    effectSizes = zeros(1, length(groups));
    
    for g = 1:length(groups)
        effectSizes(g) = groupStats.(groups{g}).meanEffectSize;
    end
    
    bar(effectSizes);
    title('Mean Effect Sizes');
    xlabel('Group');
    ylabel('Cohen''s d');
    xticklabels(groups);
    xtickangle(45);
end

function plotPValueDistribution(groupStats)
    groups = fieldnames(groupStats);
    pValues = zeros(1, length(groups));
    
    for g = 1:length(groups)
        pValues(g) = groupStats.(groups{g}).medianPValue;
    end
    
    bar(pValues);
    title('Median P-Values');
    xlabel('Group');
    ylabel('P-Value');
    xticklabels(groups);
    xtickangle(45);
end

function plotReliabilityScores(groupStats)
    groups = fieldnames(groupStats);
    reliability = zeros(1, length(groups));
    
    for g = 1:length(groups)
        reliability(g) = groupStats.(groups{g}).meanReliability;
    end
    
    bar(reliability);
    title('Mean Reliability Scores');
    xlabel('Group');
    ylabel('Reliability Score');
    xticklabels(groups);
    xtickangle(45);
end
