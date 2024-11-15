function plotPooledBaselineVsPost(expStats, ctrlStats, figureFolder)
    % Debug: Print input structure fields
    fprintf('\nDebugging input structures:\n');
    fprintf('expStats fields: %s\n', strjoin(fieldnames(expStats), ', '));
    if ~isempty(fieldnames(ctrlStats))
        fprintf('ctrlStats fields: %s\n', strjoin(fieldnames(ctrlStats), ', '));
    end
    
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
    if ~isempty(fieldnames(expStats))
        createFigureFromStats(expStats, 'Experimental', COLORS, saveDir);
    end
    if ~isempty(fieldnames(ctrlStats))
        createFigureFromStats(ctrlStats, 'Control', COLORS, saveDir);
    end
end

function createFigureFromStats(groupStats, groupTitle, colors, saveDir)
    % Debug: Print group stats structure
    fprintf('\nProcessing %s group:\n', groupTitle);
    fprintf('Group stats fields: %s\n', strjoin(fieldnames(groupStats), ', '));
    
    fig = figure('Position', [100, 100, 500, 1600]);  % Changed to vertical layout
    sgtitle(sprintf('%s Groups: Baseline vs Post-Treatment', groupTitle));
    
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    titles = {'Enhanced Units', 'Decreased Units', 'No Change Units'};
    
    for i = 1:length(responseTypes)
        subplot(1, 3, i);  % Changed to 3,1,i for vertical layout
        if isfield(groupStats, responseTypes{i})
            fprintf('\nProcessing %s - %s:\n', groupTitle, responseTypes{i});
            plotPanelFromStats(groupStats.(responseTypes{i}), titles{i}, colors.(responseTypes{i}));
        else
            title(sprintf('%s (No Data)', titles{i}));
        end
    end
    
    % Save figure
    timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
    filename = sprintf('%s_BaselineVsPost_%s.fig', groupTitle, timestamp);
    savefig(fig, fullfile(saveDir, filename));
    close(fig);
end

function plotPanelFromStats(statsData, title_str, color)
    % Debug: Print stats data structure
    fprintf('Stats data fields: %s\n', strjoin(fieldnames(statsData), ', '));
    if isfield(statsData, 'data')
        fprintf('Data fields: %s\n', strjoin(fieldnames(statsData.data), ', '));
        fprintf('Baseline size: %d, Post size: %d\n', ...
            length(statsData.data.baseline), length(statsData.data.post));
        
        % Debug: Print first few values
        if ~isempty(statsData.data.baseline)
            fprintf('First 3 baseline values: %s\n', ...
                mat2str(statsData.data.baseline(1:min(3,end)), 2));
        end
        if ~isempty(statsData.data.post)
            fprintf('First 3 post values: %s\n', ...
                mat2str(statsData.data.post(1:min(3,end)), 2));
        end
    end
    
    if isempty(statsData.data.baseline) || isempty(statsData.data.post)
        title(sprintf('%s (No Data)', title_str));
        return;
    end
    
    % Ensure data is in column format
    baseline_data = statsData.data.baseline(:);  % Force column vector
    post_data = statsData.data.post(:);         % Force column vector
    
    % Debug: Print data dimensions
    fprintf('Baseline dimensions: %s\n', mat2str(size(baseline_data)));
    fprintf('Post dimensions: %s\n', mat2str(size(post_data)));
    
    % Combine data and create grouping vector
    all_data = [baseline_data; post_data];
    groups = [ones(size(baseline_data)); 2*ones(size(post_data))];
    
    % Debug: Print combined data dimensions
    fprintf('Combined data dimensions: %s\n', mat2str(size(all_data)));
    fprintf('Groups dimensions: %s\n', mat2str(size(groups)));
    
    try
        % Create box plot with specific styling
        h = boxplot(all_data, groups, ...
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
        x1 = ones(size(baseline_data)) + (rand(size(baseline_data))-0.5)*jitterWidth;
        x2 = 2*ones(size(post_data)) + (rand(size(post_data))-0.5)*jitterWidth;
        scatter(x1, baseline_data, 15, color(1:3), 'filled', 'MarkerFaceAlpha', 0.5);
        scatter(x2, post_data, 15, color(1:3), 'filled', 'MarkerFaceAlpha', 0.5);
        
        % Set y-axis limits and ticks based on response type

        ylim([0 3.0]);
        yticks(0:0.25:3.0);
      
        % Add grid
        grid on;
        set(gca, 'Layer', 'top', ...      % Grid behind data
                'GridAlpha', 0.15, ...     % Lighter grid lines
                'FontSize', 10);           % Larger font
        
        % Add title with unit count
        title(sprintf('%s (n=%d)', title_str, length(baseline_data)), ...
              'FontSize', 11);
        
        % Add y-axis label
        ylabel('Firing Rate (Hz)', 'FontSize', 10);
        
        % Add vertical dashed line at treatment time
        xline(1.5, '--k', 'LineWidth', 1, 'Alpha', 0.5);
        
        % Add p-value and confidence intervals
        if length(data.baseline) > 1 && length(data.post) > 1
            % Get statistics - use p instead of p_holm
            p_value = statsData.testResults.wilcoxon.p;  % Changed from p_holm to p
            
            % Position text
            yRange = yMax - yMin;
            topPos = yMax - 0.05*yRange;
            midPos = yMax - 0.15*yRange;
            
            % Add p-value with significance indicator
            if p_value < 0.05  % Using standard significance threshold
                text(1.5, topPos, sprintf('p = %.3f *', p_value), ...
                     'HorizontalAlignment', 'center', ...
                     'FontSize', 10);
            else
                text(1.5, topPos, sprintf('p = %.3f', p_value), ...
                     'HorizontalAlignment', 'center', ...
                     'FontSize', 10);
            end
            
            % Add confidence intervals if they exist
            if isfield(statsData.stats, 'baseline') && isfield(statsData.stats, 'post') && ...
               isfield(statsData.stats.baseline, 'CI') && isfield(statsData.stats.post, 'CI')
                text(1.5, midPos, sprintf('CI: [%.1f, %.1f] vs [%.1f, %.1f]', ...
                     statsData.stats.baseline.CI(1), statsData.stats.baseline.CI(2), ...
                     statsData.stats.post.CI(1), statsData.stats.post.CI(2)), ...
                     'HorizontalAlignment', 'center', ...
                     'FontSize', 10);
            end
        end
    end
end