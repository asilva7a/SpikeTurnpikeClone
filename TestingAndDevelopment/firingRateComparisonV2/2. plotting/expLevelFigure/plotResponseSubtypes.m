function plotResponseSubtypes(data)
    % Create two figures - one for increased, one for decreased
    figure('Position', [100 100 1200 400], 'Name', 'Increased Units');
    figure('Position', [100 100 1200 400], 'Name', 'Decreased Units');
    
    % Define markers for groups
    markerMap = containers.Map(...
        {'Control', 'Emx', 'Pvalb'}, ...
        {'o', 's', '^'});
    
    % Extract data by response type
    increased = data(strcmp(data.ResponseType, 'Increased'), :);
    decreased = data(strcmp(data.ResponseType, 'Decreased'), :);
    
    % Plot Increased Units
    figure(1)
    subplot(1,3,1)
    [~, ~, ~, p1] = plotResponseGroup(increased(strcmp(increased.Subtype, 'Strong'), :), ...
        markerMap, 'r', 'Strong Responses', false);
    
    subplot(1,3,2)
    [~, ~, ~, p2] = plotResponseGroup(increased(strcmp(increased.Subtype, 'Moderate'), :), ...
        markerMap, 'r', 'Moderate Responses', false);
    
    subplot(1,3,3)
    [~, ~, ~, p3] = plotResponseGroup(increased(strcmp(increased.Subtype, 'Variable'), :), ...
        markerMap, 'r', 'Variable Responses', false);
    
    % Add legend to figure 1
    h3 = subplot(1,3,3);
    lineObjs = [findobj(h3, 'LineStyle', '--'); findobj(h3, 'LineStyle', ':')];
    validPlotHandles = p3(~cellfun('isempty', p3));
    allHandles = [validPlotHandles{:}, lineObjs'];
    legendLabels = [unique(increased.Group)', {'Fit', 'Unity'}];
    legend(allHandles, legendLabels, 'Location', 'northwest');
    
    % Plot Decreased Units
    figure(2)
    subplot(1,3,1)
    [~, ~, ~, p4] = plotResponseGroup(decreased(strcmp(decreased.Subtype, 'Strong'), :), ...
        markerMap, 'b', 'Strong Responses', false);
    
    subplot(1,3,2)
    [~, ~, ~, p5] = plotResponseGroup(decreased(strcmp(decreased.Subtype, 'Moderate'), :), ...
        markerMap, 'b', 'Moderate Responses', false);
    
    subplot(1,3,3)
    [~, ~, ~, p6] = plotResponseGroup(decreased(strcmp(decreased.Subtype, 'Variable'), :), ...
        markerMap, 'b', 'Variable Responses', false);
    
    % Add legend to figure 2
    h6 = subplot(1,3,3);
    lineObjs = [findobj(h6, 'LineStyle', '--'); findobj(h6, 'LineStyle', ':')];
    validPlotHandles = p6(~cellfun('isempty', p6));
    allHandles = [validPlotHandles{:}, lineObjs'];
    legendLabels = [unique(decreased.Group)', {'Fit', 'Unity'}];
    legend(allHandles, legendLabels, 'Location', 'northwest');
end

function [equation, r2, residuals, plotHandles] = plotResponseGroup(data, markerMap, color, titleStr, showLegend)
    hold on;
    
    % Initialize plot handles array
    plotHandles = cell(1, length(unique(data.Group)));
    
    % Plot each group
    groups = unique(data.Group);
    for i = 1:length(groups)
        groupData = data(strcmp(data.Group, groups{i}), :);
        plotHandles{i} = scatter(groupData.mean_pre, groupData.mean_post, 100, ...
            color, 'filled', ...
            'Marker', markerMap(groups{i}), ...
            'MarkerFaceAlpha', 0.6, ...
            'MarkerEdgeColor', 'k');
    end
    
    % Calculate and plot regression
    if ~isempty(data)
        x = data.mean_pre;
        y = data.mean_post;
        p = polyfit(x, y, 1);
        yfit = polyval(p, x);
        residuals = y - yfit;
        
        r2 = 1 - sum(residuals.^2)/sum((y - mean(y)).^2);
        
        xrange = linspace(min(x), max(x), 100);
        plot(xrange, polyval(p, xrange), 'k--', 'LineWidth', 1.5);
        
        equation = sprintf('y = %.3fx + %.3f', p(1), p(2));
        
        % Position text in bottom right
        text(0.95, 0.05, sprintf('%s\nR^2 = %.3f', equation, r2), ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'bottom', ...
            'HorizontalAlignment', 'right');
    else
        equation = '';
        r2 = NaN;
        residuals = [];
    end
    
    % Add unity line
    maxVal = max([data.mean_pre; data.mean_post]) * 1.1;
    if isempty(maxVal) || maxVal == 0
        maxVal = 1;
    end
    plot([0 maxVal], [0 maxVal], 'k:', 'LineWidth', 1);
    
    % Format plot
    title(titleStr);
    xlabel('Pre-stimulus Firing Rate (Hz)');
    ylabel('Post-stimulus Firing Rate (Hz)');
    grid on;
    axis square;
    
    if ~isempty(maxVal)
        xlim([-maxVal*0.05 maxVal]);
        ylim([-maxVal*0.05 maxVal]);
    end
    
    hold off;
end