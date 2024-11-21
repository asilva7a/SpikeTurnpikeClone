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
            unit_metadata_table = table();
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                if isfield(unitData, 'Amplitude') && ~isempty(unitData.Amplitude)
                    amplitudes = unitData.Amplitude(:);
                    amplitudes = amplitudes(isfinite(amplitudes));
                    
                    % Store unit metadata
                    unit_row = table();
                    unit_row.UnitID = {unitID};
                    if isfield(unitData, 'CellType')
                        unit_row.CellType = {unitData.CellType};
                    end
                    if isfield(unitData, 'IsSingleUnit')
                        unit_row.IsSingleUnit = unitData.IsSingleUnit;
                    end
                    unit_metadata_table = [unit_metadata_table; unit_row];
                    
                    % Append amplitudes for recording level analysis
                    all_recording_amplitudes = [all_recording_amplitudes; amplitudes];
                    
                    % Store data for project-wide boxplot
                    all_amplitudes = [all_amplitudes; amplitudes];
                    recording_labels = [recording_labels; repmat({recordingName}, length(amplitudes), 1)];
                    group_labels = [group_labels; repmat({groupName}, length(amplitudes), 1)];
                end
            end
            
            % Calculate recording level stats
            if ~isempty(all_recording_amplitudes)
                recording_stats = calculate_unit_stats(all_recording_amplitudes, 'recording');
                stats_by_level.(groupName).(recordingName).summary = recording_stats;
                
                % Plot recording level
                plot_level_stats(all_recording_amplitudes, recording_stats, ...
                    sprintf('%s_%s_Recording', groupName, recordingName), save_path);
                
                % Save unit metadata table
                writetable(unit_metadata_table, fullfile(save_path, ...
                    sprintf('%s_%s_units_metadata.csv', groupName, recordingName)));
                
                % Append to group level
                all_group_amplitudes = [all_group_amplitudes; all_recording_amplitudes];
            end
        end
        
        % Calculate group level stats
        if ~isempty(all_group_amplitudes)
            group_stats = calculate_unit_stats(all_group_amplitudes, 'group');
            stats_by_level.(groupName).summary = group_stats;
            
            % Plot group level
            plot_level_stats(all_group_amplitudes, group_stats, ...
                sprintf('%s_Group', groupName), save_path);
        end
    end
    
    % Plot project-wide violin plot with points
    if ~isempty(all_amplitudes)
        plot_project_violin(all_amplitudes, recording_labels, group_labels, save_path);
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
    
    % Only calculate CI and normality test for group/recording levels
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

function plot_project_violin(amplitudes, recording_labels, group_labels, save_path)
    figure('Name', 'Project-wide Recording Comparisons', 'Position', [100 100 1200 600]);
    
    % Get unique groups and assign colors
    unique_groups = unique(group_labels);
    colors = lines(length(unique_groups));
    color_map = containers.Map(unique_groups, num2cell(colors, 2));
    
    % Create violin plot
    violinplot(amplitudes, recording_labels, 'GroupByColor', group_labels);
    
    hold on
    unique_recordings = unique(recording_labels);
    for i = 1:length(unique_recordings)
        % Get data points for this recording
        idx = strcmp(recording_labels, unique_recordings{i});
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
    savefig(fullfile(save_path, 'project_amplitude_violinplot.fig'));
    saveas(gcf, fullfile(save_path, 'project_amplitude_violinplot.png'));
    close(gcf);
end