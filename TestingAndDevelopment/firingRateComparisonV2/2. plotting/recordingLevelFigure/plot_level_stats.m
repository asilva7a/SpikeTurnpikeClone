function plot_level_stats(amplitudes, stats, level_name, save_path)
    figure('Name', sprintf('Amplitude Statistics - %s', level_name));
    
    % Plot amplitude distribution
    histogram(amplitudes, 50, 'Normalization', 'probability');
    hold on
    
    % Add mean and CI lines
    yl = ylim;
    plot([stats.mean stats.mean], yl, 'r-', 'LineWidth', 2);
    if isfield(stats, 'CI_lower')
        plot([stats.CI_lower stats.CI_lower], yl, 'r--');
        plot([stats.CI_upper stats.CI_upper], yl, 'r--');
    end
    
    xlabel('Spike Amplitude (µV)');
    ylabel('Probability');
    if isfield(stats, 'normality_test')
        title(sprintf('Amplitude Distribution - %s\nNormality Test p-value: %.3f', ...
            level_name, stats.normality_test.p_value));
    else
        title(sprintf('Amplitude Distribution - %s', level_name));
    end
    legend('Amplitude Distribution', 'Mean', '95% CI');
    
    % Save figure
    savefig(fullfile(save_path, sprintf('%s_amplitude_distribution.fig', level_name)));
    saveas(gcf, fullfile(save_path, sprintf('%s_amplitude_distribution.png', level_name)));
    close(gcf);
end
