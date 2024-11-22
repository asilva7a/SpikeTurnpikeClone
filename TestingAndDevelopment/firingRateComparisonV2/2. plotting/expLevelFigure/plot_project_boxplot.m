function plot_project_boxplot(amplitudes, recording_labels, group_labels, save_path)
    figure('Name', 'Project-wide Recording Comparisons', 'Position', [100 100 1200 600]);
    
    % Get unique groups and assign colors
    unique_groups = unique(group_labels);
    colors = lines(length(unique_groups));
    color_map = containers.Map(unique_groups, num2cell(colors, 2));
    
    % Create boxplot
    [g, recording_names] = findgroups(recording_labels);
    boxplot(amplitudes, g, 'Labels', recording_names, 'Orientation', 'vertical');
    
    % Add individual points
    hold on
    for i = 1:length(recording_names)
        idx = strcmp(recording_labels, recording_names{i});
        recording_group = group_labels{find(idx, 1)};
        
        % Add jittered scatter plot
        x = rand(sum(idx),1)*0.4 - 0.2 + i;
        y = amplitudes(idx);
        scatter(x, y, 20, color_map(recording_group), 'filled', 'MarkerFaceAlpha', 0.3);
    end
    hold off
    
    % Customize plot
    xlabel('Recordings');
    ylabel('Amplitude (µV)');
    title('Amplitude Distribution Across Recordings');
    
    % Rotate x-axis labels for better readability
    xtickangle(45);
    
    % Adjust figure size to accommodate labels
    set(gca, 'Position', [0.1 0.2 0.7 0.7]);
    
    % Save figure
    savefig(fullfile(save_path, 'project_amplitude_boxplot.fig'));
    saveas(gcf, fullfile(save_path, 'project_amplitude_boxplot.png'));
    close(gcf);
end
