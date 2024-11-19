function plotPooledZScoreBaselineVsPost(expStats, ctrlStats, figureFolder)
    % Constants
    COLORS = struct(...
        'Increased', [1, 0, 0, 0.3], ...    % Red
        'Decreased', [0, 0, 1, 0.3], ...    % Blue
        'No_Change', [0.5, 0.5, 0.5, 0.3]);  % Grey
    
    % Create save directory
    saveDir = fullfile(figureFolder, '0. expFigures');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    
    % Create figures
    if ~isempty(fieldnames(expStats))
        createFigureFromStats(expStats, 'Experimental', COLORS, saveDir);
    end
    if ~isempty(fieldnames(ctrlStats)) 
        createFigureFromStats(ctrlStats, 'Control', COLORS, saveDir);
    end
end

function createFigureFromStats(groupStats, groupTitle, colors, saveDir)
    % Create figure with better proportions
    fig = figure('Position', [100, 100, 1200, 400]);  % Wider, shorter figure
    
    % Create tile layout for better spacing
    t = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % Main title with better positioning
    title(t, sprintf('%s Groups: Baseline vs Post-Treatment Z-Scores', groupTitle), ...
        'FontSize', 14, 'FontWeight', 'bold');
    
    responseTypes = {'Increased', 'Decreased', 'No_Change'};
    titles = {'Enhanced Units', 'Decreased Units', 'No Change Units'};
    
    % Process each response type
    for i = 1:length(responseTypes)
        nexttile(i);
        if isfield(groupStats, responseTypes{i})
            plotPanelFromStats(groupStats.(responseTypes{i}), titles{i}, colors.(responseTypes{i}));
        else
            % Consistent empty plot formatting
            axis([0.5 2.5 -3 3]);  % Changed y-limits for Z-scores
            grid on;
            set(gca, 'Layer', 'top', ...
                'GridAlpha', 0.15, ...
                'FontSize', 10, ...
                'XTick', [1 2], ...
                'XTickLabel', {'Baseline', 'Post'}, ...
                'YTick', -3:1:3);  % Changed y-ticks for Z-scores
            title(sprintf('%s (No Data)', titles{i}));
            ylabel('Z-Score');
        end
    end
    
    % Save figure with consistent naming
    timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
    filename = sprintf('%s_ZScore_BaselineVsPost_%s', groupTitle, timestamp);
    savefig(fig, fullfile(saveDir, [filename '.fig']));
    print(fig, fullfile(saveDir, [filename '.tif']), '-dtiff', '-r300');
    close(fig);
end

function plotPanelFromStats(statsData, title_str, color)
    if isempty(statsData.data.baseline) || isempty(statsData.data.post)
        return;
    end
    
    % Ensure data is in column format
    baseline_data = statsData.data.baseline(:);
    post_data = statsData.data.post(:);
    
    % Create box plot
    h = boxplot([baseline_data; post_data], ...
        [ones(size(baseline_data)); 2*ones(size(post_data))], ...
        'Labels', {'Baseline', 'Post'}, ...
        'Colors', 'k', ...
        'Width', 0.7, ...
        'Symbol', '', ...
        'Whisker', 1.5);
    
    % Style the box plot
    set(findobj(gca, 'type', 'line'), 'LineWidth', 1);
    h = findobj(gca, 'Tag', 'Box');
    for j = 1:length(h)
        patch(get(h(j), 'XData'), get(h(j), 'YData'), color(1:3), ...
            'FaceAlpha', 0.3, ...
            'EdgeColor', 'k');
    end
    
    hold on;
    
    % Add jittered points
    jitterWidth = 0.2;
    x1 = ones(size(baseline_data)) + (rand(size(baseline_data))-0.5)*jitterWidth;
    x2 = 2*ones(size(post_data)) + (rand(size(post_data))-0.5)*jitterWidth;
    scatter(x1, baseline_data, 15, color(1:3), 'filled', 'MarkerFaceAlpha', 0.5);
    scatter(x2, post_data, 15, color(1:3), 'filled', 'MarkerFaceAlpha', 0.5);
    
    % Consistent axis formatting for Z-scores
    axis([0.5 2.5 -1 3]);  % Changed y-limits for Z-scores
    set(gca, 'XTick', [1 2], ...
        'XTickLabel', {'Baseline', 'Post'}, ...
        'YTick', -3:1:3, ...  % Changed y-ticks for Z-scores
        'FontSize', 10);
    
    % Add grid
    grid on;
    set(gca, 'Layer', 'top', 'GridAlpha', 0.15);
    
    % Add title and labels
    title(sprintf('%s (n=%d)', title_str, length(baseline_data)), ...
        'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Z-Score', 'FontSize', 10);
    
    % Add treatment line
    xline(1.5, '--k', 'LineWidth', 1, 'Alpha', 0.5);
    
    % Add statistics if available
    if isfield(statsData, 'testResults') && ...
       isfield(statsData.testResults, 'wilcoxon') && ...
       isfield(statsData.testResults.wilcoxon, 'p')
        
        p_value = statsData.testResults.wilcoxon.p;
        ypos = 2.5;  % Adjusted position for p-value in Z-score scale
        xpos = 1.65; % Moved right of the dotted line (1.5)
        
        if p_value < 0.05
            text(xpos, ypos, sprintf('p = %.3f *', p_value), ...
                'HorizontalAlignment', 'left', ... % Changed to left alignment
                'FontSize', 10);
        else
            text(xpos, ypos, sprintf('p = %.3f', p_value), ...
                'HorizontalAlignment', 'left', ... % Changed to left alignment
                'FontSize', 10);
        end
    end

    
    % Add zero line for Z-scores
    yline(0, '-k', 'LineWidth', 0.5, 'Alpha', 0.3);
    
    hold off;
end