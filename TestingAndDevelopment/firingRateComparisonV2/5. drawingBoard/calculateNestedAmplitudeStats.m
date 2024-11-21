function [stats_by_level] = calculateNestedAmplitudeStats(cellDataStruct, save_path)
    % Initialize structure to store stats at each level
    stats_by_level = struct();
    
    % Get group names
    groupNames = fieldnames(cellDataStruct);
    
    % Initialize arrays for project-wide boxplot
    all_amplitudes = [];
    recording_labels = {};
    group_labels = {};
    
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Group level arrays
        all_group_amplitudes = [];
        group_stats_table = table();
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Recording level arrays
            all_recording_amplitudes = [];
            recording_stats_table = table();
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                if isfield(unitData, 'Amplitude') && ~isempty(unitData.Amplitude)
                    amplitudes = unitData.Amplitude(:);
                    amplitudes = amplitudes(isfinite(amplitudes));
                    
                    % Calculate unit statistics (basic stats only)
                    unit_stats = calculate_unit_stats(amplitudes, 'unit');
                    
                    % Store unit stats and append data
                    stats_by_level.(groupName).(recordingName).(unitID) = unit_stats;
                    all_recording_amplitudes = [all_recording_amplitudes; amplitudes];
                    
                    % Store data for project-wide boxplot
                    all_amplitudes = [all_amplitudes; amplitudes];
                    recording_labels = [recording_labels; repmat({recordingName}, length(amplitudes), 1)];
                    group_labels = [group_labels; repmat({groupName}, length(amplitudes), 1)];
                    
                    % Add to recording table with metadata
                    unit_row = struct2table(unit_stats, 'AsArray', true);
                    unit_row.UnitID = {unitID};
                    if isfield(unitData, 'CellType')
                        unit_row.CellType = {unitData.CellType};
                    end
                    if isfield(unitData, 'IsSingleUnit')
                        unit_row.IsSingleUnit = unitData.IsSingleUnit;
                    end
                    recording_stats_table = [recording_stats_table; unit_row];
                end
            end
            
            % Calculate recording level stats with CI
            if ~isempty(all_recording_amplitudes)
                recording_stats = calculate_unit_stats(all_recording_amplitudes, 'recording');
                stats_by_level.(groupName).(recordingName).summary = recording_stats;
                
                % Plot recording level
                plot_level_stats(all_recording_amplitudes, recording_stats, ...
                    sprintf('%s_%s_Recording', groupName, recordingName), save_path);
                
                % Save recording table
                writetable(recording_stats_table, fullfile(save_path, ...
                    sprintf('%s_%s_units_with_metadata.csv', groupName, recordingName)));
                
                % Append to group level
                all_group_amplitudes = [all_group_amplitudes; all_recording_amplitudes];
            end
        end
        
        % Calculate group level stats with CI
        if ~isempty(all_group_amplitudes)
            group_stats = calculate_unit_stats(all_group_amplitudes, 'group');
            stats_by_level.(groupName).summary = group_stats;
            
            % Plot group level
            plot_level_stats(all_group_amplitudes, group_stats, ...
                sprintf('%s_Group', groupName), save_path);
        end
    end
    
    % Plot project-wide boxplot
    if ~isempty(all_amplitudes)
        plot_project_boxplot(all_amplitudes, recording_labels, group_labels, save_path);
    end
end

function stats = calculate_unit_stats(amplitudes, level)
    % Calculate basic statistics
    stats.n_samples = length(amplitudes);
    stats.mean = mean(amplitudes);
    stats.median = median(amplitudes);
    stats.min = min(amplitudes);
    stats.max = max(amplitudes);
    stats.std = std(amplitudes);
    stats.std_error = stats.std / sqrt(stats.n_samples);
    stats.range = stats.max - stats.min;
    
    % Calculate CI and normality only for recording and group levels
    if nargin > 1 && (strcmp(level, 'group') || strcmp(level, 'recording'))
        % Test for normality using Lilliefors test
        [h, p_value] = lillietest(amplitudes);
        stats.normality_test = struct('h', h, 'p_value', p_value);
        stats.is_normal = ~h;
        
        % Calculate 95% CI using t-distribution
        alpha = 0.05;
        t_score = tinv(1-alpha/2, stats.n_samples-1);
        stats.CI_lower = stats.mean - t_score * stats.std_error;
        stats.CI_upper = stats.mean + t_score * stats.std_error;
    end
end

function plot_level_stats(amplitudes, stats, level_name, save_path)
    figure('Name', sprintf('Amplitude Statistics - %s', level_name));
    
    % Plot amplitude distribution
    histogram(amplitudes, 50, 'Normalization', 'probability');
    hold on
    
    % Add mean and CI lines
    yl = ylim;
    plot([stats.mean stats.mean], yl, 'r-', 'LineWidth', 2);
    plot([stats.CI_lower stats.CI_lower], yl, 'r--');
    plot([stats.CI_upper stats.CI_upper], yl, 'r--');
    
    xlabel('Spike Amplitude (µV)');
    ylabel('Probability');
    title(sprintf('Amplitude Distribution - %s\nNormality Test p-value: %.3f', ...
        level_name, stats.normality_test.p_value));
    legend('Amplitude Distribution', 'Mean', '95% CI');
    
    % Save figure
    savefig(fullfile(save_path, sprintf('%s_amplitude_distribution.fig', level_name)));
    saveas(gcf, fullfile(save_path, sprintf('%s_amplitude_distribution.png', level_name)));
    close(gcf);
end

function plot_project_boxplot(amplitudes, recording_labels, group_labels, save_path)
    figure('Name', 'Project-wide Recording Comparisons', 'Position', [100 100 1200 600]);
    
    % Get unique groups and assign colors
    unique_groups = unique(group_labels);
    colors = lines(length(unique_groups));
    color_map = containers.Map(unique_groups, num2cell(colors, 2));
    
    % Create boxplot
    [g, recording_names] = findgroups(recording_labels);
    boxplot(amplitudes, g, 'Labels', recording_names, 'Orientation', 'vertical');

    % Create violin plot
    violinplot(amplitudes, recording_labels, 'GroupByColor', group_labels);
    
    % Customize boxplot colors by group
    h = findobj(gca, 'Tag', 'Box');
    for j = 1:length(recording_names)
        % Find group for this recording
        recording_group = group_labels{find(strcmp(recording_labels, recording_names{j}), 1)};
        patch(get(h(end-j+1), 'XData'), get(h(end-j+1), 'YData'), ...
            color_map(recording_group), 'FaceAlpha', 0.5);
    end
    
    % Add individual points
    hold on
    for i = 1:length(recording_names)
        % Get data points for this recording
        idx = strcmp(recording_labels, recording_names{i});
        recording_group = group_labels{find(idx, 1)};
        
        % Add jittered scatter plot
        x = rand(sum(idx),1)*0.4 - 0.2 + i;
        scatter(x, amplitudes(idx), 20, color_map(recording_group), 'filled', 'MarkerFaceAlpha', 0.3);
    end
    hold off
    
    % Add legend for groups
    legend_handles = [];
    legend_labels = {};
    for i = 1:length(unique_groups)
        legend_handles(i) = patch(NaN, NaN, colors(i,:), 'FaceAlpha', 0.5);
        legend_labels{i} = unique_groups{i};
    end
    legend(legend_handles, legend_labels, 'Location', 'eastoutside');
    
    % Rotate x-axis labels for better readability
    xtickangle(45);
    
    % Adjust figure size to accommodate labels
    set(gca, 'Position', [0.1 0.2 0.7 0.7]);
    
    % Save figure
    savefig(fullfile(save_path, 'project_amplitude_boxplot.fig'));
    saveas(gcf, fullfile(save_path, 'project_amplitude_boxplot.png'));
    close(gcf);
end
