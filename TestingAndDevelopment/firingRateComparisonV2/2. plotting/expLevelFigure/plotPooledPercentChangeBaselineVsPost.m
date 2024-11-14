function plotPooledPercentChangeBaselineVsPost(cellDataStruct, figureFolder, treatmentTime, unitFilter, outlierFilter)
    % Set defaults
    if nargin < 5, outlierFilter = true; end
    if nargin < 4, unitFilter = 'both'; end
    if nargin < 3, treatmentTime = 1860; end
    
    % Constants
    COLORS = struct(...
        'Increased', [1, 0, 0, 0.3], ...    % Red
        'Decreased', [0, 0, 1, 0.3], ...    % Blue
        'NoChange', [0.5, 0.5, 0.5, 0.3]);  % Grey
    
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
    
    % Create figures
    createAndSaveFigures(expData, ctrlData, COLORS, figureFolder);
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
                
                % Calculate mean percent changes
                baselinePC = mean(unitData.psthPercentChange(baselineIdx), 'omitnan');
                postPC = mean(unitData.psthPercentChange(postIdx), 'omitnan');
                
                % Store data
                data.(responseType).baseline(end+1) = baselinePC;
                data.(responseType).post(end+1) = postPC;
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
    isValid = isfield(unitData, 'psthPercentChange') && ...
              isfield(unitData, 'responseType') && ...
              isfield(unitData, 'binEdges') && ...
              isfield(unitData, 'binWidth');
end

function createAndSaveFigures(expData, ctrlData, colors, figureFolder)
    % Create save directory
    saveDir = fullfile(figureFolder, '0. expFigures');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    
    % Create figures
    createFigure(expData, 'Experimental', colors, saveDir);
    if ~isempty(fieldnames(ctrlData))
        createFigure(ctrlData, 'Control', colors, saveDir);
    end
end

function createFigure(data, groupTitle, colors, saveDir)
    fig = figure('Position', [100, 100, 1600, 500]);
    sgtitle(sprintf('%s Groups: Baseline vs Post-Treatment', groupTitle));
    
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    titles = {'Enhanced Units', 'Decreased Units', 'No Change Units'};
    
    for i = 1:length(responseTypes)
        subplot(1, 3, i);
        plotPanel(data.(responseTypes{i}), titles{i}, colors.(responseTypes{i}));
    end
    
    % Save figure
    timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
    filename = sprintf('%s_PercentChangeBaselineVsPost_%s.fig', groupTitle, timestamp);
    savefig(fig, fullfile(saveDir, filename));
    close(fig);
end

function plotPanel(data, title_str, color)
    if isempty(data.baseline) || isempty(data.post)
        title(sprintf('%s (No Data)', title_str));
        return;
    end
    
    % Create box plot with specific styling
    h = boxplot([data.baseline', data.post'], ...
                'Labels', {'Baseline', 'Post'}, ...
                'Colors', 'k', ...         % Black lines for box
                'Width', 0.7, ...          % Wider boxes
                'Symbol', '', ...          % No outlier symbols
                'Whisker', 1.5);          % Standard whisker length
    
    % Set all lines to be thinner
    set(findobj(gca, 'type', 'line'), 'LineWidth', 1);
    
    % Color the boxes with transparency
    h = findobj(gca, 'Tag', 'Box');
    for j = 1:length(h)
        patch(get(h(j), 'XData'), get(h(j), 'YData'), color(1:3), ...
              'FaceAlpha', 0.3, ...
              'EdgeColor', 'k');
    end
    
    hold on;
    
    % Add individual points with jitter
    jitterWidth = 0.2;
    x1 = ones(size(data.baseline)) + (rand(size(data.baseline))-0.5)*jitterWidth;
    x2 = 2*ones(size(data.post)) + (rand(size(data.post))-0.5)*jitterWidth;
    scatter(x1, data.baseline, 15, color(1:3), 'filled', 'MarkerFaceAlpha', 0.5);
    scatter(x2, data.post, 15, color(1:3), 'filled', 'MarkerFaceAlpha', 0.5);
    
    % Set y-axis limits and ticks based on response type
    if contains(title_str, 'Enhanced')
        ylim([-100 400]);
        yticks(-100:100:400);
    elseif contains(title_str, 'Decreased')
        ylim([-100 100]);
        yticks(-100:50:100);
    else  % No Change
        ylim([-100 100]);
        yticks(-100:50:100);
    end
    
    % Add grid
    grid on;
    set(gca, 'Layer', 'top', ...      % Grid behind data
            'GridAlpha', 0.15, ...     % Lighter grid lines
            'FontSize', 10);           % Larger font
    
    % Add title with unit count
    title(sprintf('%s (n=%d)', title_str, length(data.baseline)), ...
          'FontSize', 11);
    
    % Add y-axis label
    ylabel('% Change from Baseline', 'FontSize', 10);
    
    % Add vertical dashed line at treatment time
    xline(1.5, '--k', 'LineWidth', 1, 'Alpha', 0.5);
    
    % Add statistics
    if length(data.baseline) > 1 && length(data.post) > 1
        [~, p] = ttest2(data.baseline, data.post);
        if p < 0.05
            text(1.5, max(ylim)*0.95, sprintf('p = %.3f *', p), ...
                 'HorizontalAlignment', 'center', ...
                 'FontSize', 10);
        else
            text(1.5, max(ylim)*0.95, sprintf('p = %.3f', p), ...
                 'HorizontalAlignment', 'center', ...
                 'FontSize', 10);
        end
    end
    
    hold off;
end
