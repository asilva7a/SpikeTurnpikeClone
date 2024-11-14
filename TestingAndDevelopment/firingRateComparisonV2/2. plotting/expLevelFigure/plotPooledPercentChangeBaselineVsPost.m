function plotPooledPercentChangeBaselineVsPost(expStats, ctrlStats, figureFolder)
    % Constants
    COLORS = struct(...
        'Increased', [1, 0, 0, 0.3], ...    % Red
        'Decreased', [0, 0, 1, 0.3], ...    % Blue
        'NoChange', [0.5, 0.5, 0.5, 0.3]);  % Grey
    
    % Create save directory
    saveDir = fullfile(figureFolder, '0. expFigures');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    
    % Create figures
    createFigureFromStats(expStats, 'Experimental', COLORS, saveDir);
    if ~isempty(fieldnames(ctrlStats))
        createFigureFromStats(ctrlStats, 'Control', COLORS, saveDir);
    end
end

function createFigureFromStats(groupStats, groupTitle, colors, saveDir)
    fig = figure('Position', [100, 100, 1600, 500]);
    sgtitle(sprintf('%s Groups: Baseline vs Post-Treatment', groupTitle));
    
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    titles = {'Enhanced Units', 'Decreased Units', 'No Change Units'};
    
    % Find global y-limits across all panels
    yMin = Inf;
    yMax = -Inf;
    for i = 1:length(responseTypes)
        if isfield(groupStats, responseTypes{i}) && ~isempty(groupStats.(responseTypes{i}).data)
            data = groupStats.(responseTypes{i}).data;
            yMin = min(yMin, min([data.baseline(:); data.post(:)]));
            yMax = max(yMax, max([data.baseline(:); data.post(:)]));
        end
    end
    
    % Add padding to y-limits
    yRange = yMax - yMin;
    yMin = yMin - 0.1 * yRange;
    yMax = yMax + 0.1 * yRange;
    
    % Create subplots
    for i = 1:length(responseTypes)
        subplot(1, 3, i);
        if isfield(groupStats, responseTypes{i})
            plotPanelFromStats(groupStats.(responseTypes{i}), titles{i}, colors.(responseTypes{i}), yMin, yMax);
        else
            title(sprintf('%s (No Data)', titles{i}));
        end
    end
    
    % Save figure
    timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
    filename = sprintf('%s_PercentChangeBaselineVsPost_%s.fig', groupTitle, timestamp);
    savefig(fig, fullfile(saveDir, filename));
    close(fig);
end

function plotPanelFromStats(statsData, title_str, color, yMin, yMax)
    if isempty(statsData.data.baseline) || isempty(statsData.data.post)
        title(sprintf('%s (No Data)', title_str));
        return;
    end
    
    data = statsData.data;
    
    % Create box plot with specific styling
    h = boxplot([data.baseline', data.post'], ...
                'Labels', {'Baseline', 'Post'}, ...
                'Colors', 'k', ...
                'Width', 0.7, ...
                'Symbol', '', ...
                'Whisker', 1.5);
    
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
    
    % Set consistent y-axis limits
    ylim([yMin yMax]);
    yticks(linspace(yMin, yMax, 6));
    
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
    
    % Add p-value and effect size
    if length(data.baseline) > 1 && length(data.post) > 1
        p_value = statsData.testResults.wilcoxon.p;
        cohens_d = statsData.testResults.cohens_d;
        
        % Position text
        yRange = yMax - yMin;
        topPos = yMax - 0.05*yRange;
        midPos = yMax - 0.15*yRange;
        
        % Add p-value with significance indicator
        if p_value < 0.05
            text(1.5, topPos, sprintf('p = %.3f *', p_value), ...
                 'HorizontalAlignment', 'center', ...
                 'FontSize', 10);
        else
            text(1.5, topPos, sprintf('p = %.3f', p_value), ...
                 'HorizontalAlignment', 'center', ...
                 'FontSize', 10);
        end
        
        % Add effect size with interpretation
        effectSize = '';
        if abs(cohens_d) < 0.2
            effectSize = 'negligible';
        elseif abs(cohens_d) < 0.5
            effectSize = 'small';
        elseif abs(cohens_d) < 0.8
            effectSize = 'medium';
        else
            effectSize = 'large';
        end
        
        text(1.5, midPos, sprintf('d = %.2f (%s)', cohens_d, effectSize), ...
             'HorizontalAlignment', 'center', ...
             'FontSize', 10);
    end
    
    hold off;
end
