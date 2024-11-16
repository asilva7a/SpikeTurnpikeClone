function plotNormalizedExp_And_CtrlPSTH(expPSTH, ctrlPSTH, normPSTH)
    % Create figure
    fig = figure('Position', [100, 100, 1600, 500]);
    
    % Plot experimental vs control
    subplot(3, 1, 1)
    plotPSTHPanel(expPSTH, ctrlPSTH, 'Experimental vs Control')
    
    % Plot normalized
    subplot(3, 1, 2)
    plotNormalizedPanel(normPSTH, 'Normalized to Control')
    
    % Plot all together
    subplot(3, 1, 3)
    plotAllPanel(expPSTH, ctrlPSTH, normPSTH, 'Combined View')
end

function plotPSTHPanel(expPSTH, ctrlPSTH, titleStr)
    hold on
    
    % Plot experimental with error bars
    shadedErrorBar(expPSTH.timeVector, expPSTH.mean, expPSTH.sem, ...
                  'lineProps', {'Color', [1 0 0], 'LineWidth', 2});
    
    % Plot control with error bars
    shadedErrorBar(ctrlPSTH.timeVector, ctrlPSTH.mean, ctrlPSTH.sem, ...
                  'lineProps', {'Color', [0 0 1], 'LineWidth', 2});
    
    % Add vertical line at treatment time (assuming 1860)
    xline(1860, '--k', 'LineWidth', 1.5);
    
    % Formatting
    title(sprintf('%s\n(nExp=%d, nCtrl=%d)', titleStr, expPSTH.n, ctrlPSTH.n))
    xlabel('Time (s)')
    ylabel('Firing Rate (Hz)')
    legend('Experimental', 'Control')
    grid on
    hold off
end

function plotNormalizedPanel(normPSTH, titleStr)
    hold on
    
    % Plot normalized data with error bars
    shadedErrorBar(normPSTH.timeVector, normPSTH.mean, normPSTH.sem, ...
                  'lineProps', {'Color', [0.5 0 0.5], 'LineWidth', 2});
    
    % Add horizontal line at 1 (baseline)
    yline(1, '--k', 'LineWidth', 1);
    
    % Add vertical line at treatment time
    xline(1860, '--k', 'LineWidth', 1.5);
    
    % Formatting
    title(titleStr)
    xlabel('Time (s)')
    ylabel('Normalized FR (Exp/Ctrl)')
    grid on
    hold off
end

function plotAllPanel(expPSTH, ctrlPSTH, normPSTH, titleStr)
    hold on
    
    % Create two y-axes
    yyaxis left
    % Plot experimental and control
    shadedErrorBar(expPSTH.timeVector, expPSTH.mean, expPSTH.sem, ...
                  'lineProps', {'Color', [1 0 0], 'LineWidth', 2});
    shadedErrorBar(ctrlPSTH.timeVector, ctrlPSTH.mean, ctrlPSTH.sem, ...
                  'lineProps', {'Color', [0 0 1], 'LineWidth', 2});
    ylabel('Firing Rate (Hz)')
    
    yyaxis right
    % Plot normalized
    shadedErrorBar(normPSTH.timeVector, normPSTH.mean, normPSTH.sem, ...
                  'lineProps', {'Color', [0.5 0 0.5], 'LineWidth', 2});
    ylabel('Normalized FR')
    
    % Add vertical line at treatment time
    xline(1860, '--k', 'LineWidth', 1.5);
    
    % Formatting
    title(titleStr)
    xlabel('Time (s)')
    legend('Experimental', 'Control', 'Normalized')
    grid on
    hold off
end
