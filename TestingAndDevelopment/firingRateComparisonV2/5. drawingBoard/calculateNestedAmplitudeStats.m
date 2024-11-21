function [stats_by_level] = calculateNestedAmplitudeStats(cellDataStruct, save_path)
    % Initialize structure to store stats at each level
    stats_by_level = struct();
    
    % Get group names
    groupNames = fieldnames(cellDataStruct);
    
    % Initialize arrays for project-wide boxplot
    all_amplitudes = [];
    recording_labels = {};
    group_labels = {};
    
    % Project level arrays to collect all amplitudes
    all_project_amplitudes = [];
    
     for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Group level arrays
        all_group_spikes = [];
        all_group_amplitudes = [];
        group_stats_table = table();
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Recording level arrays
            all_recording_spikes = [];
            all_recording_amplitudes = [];
            recording_stats_table = table();
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                if isfield(unitData, 'Amplitude') && ~isempty(unitData.Amplitude) && ...
                   isfield(unitData, 'SpikeTimesall') && ~isempty(unitData.SpikeTimesall)
                    amplitudes = unitData.Amplitude(:);
                    amplitudes = amplitudes(isfinite(amplitudes));
                    
                    % Calculate unit statistics with spike times
                    unit_stats = calculate_unit_stats(amplitudes, unitData.SpikeTimesall);
                    
                    % Store unit stats and append data
                    stats_by_level.(groupName).(recordingName).(unitID) = unit_stats;
                    all_recording_amplitudes = [all_recording_amplitudes; amplitudes];
                    all_recording_spikes = [all_recording_spikes; unitData.SpikeTimesall(:)];
                    
                    % Add to recording table
                    unit_row = struct2table(unit_stats, 'AsArray', true);
                    unit_row.UnitID = {unitID};
                    recording_stats_table = [recording_stats_table; unit_row];
                end
            end
            
            % Calculate recording level stats with combined spike times
            if ~isempty(all_recording_amplitudes)
                recording_stats = calculate_unit_stats(all_recording_amplitudes, all_recording_spikes);
                stats_by_level.(groupName).(recordingName).summary = recording_stats;
                
                % Plot recording level
                plot_level_stats(all_recording_amplitudes, recording_stats, ...
                    sprintf('%s_%s_Recording', groupName, recordingName), save_path);
                
                % Save recording table with metadata
                writetable(recording_stats_table, fullfile(save_path, ...
                    sprintf('%s_%s_units_with_metadata.csv', groupName, recordingName)));
                
                % Append to group level
                all_group_amplitudes = [all_group_amplitudes; all_recording_amplitudes];
                all_group_spikes = [all_group_spikes; all_recording_spikes];
                
                % Add to group table with metadata
                recording_row = struct2table(recording_stats, 'AsArray', true);
                recording_row.Recording = {recordingName};
                recording_row.NumUnits = height(recording_stats_table);
                recording_row.NumSingleUnits = sum([recording_stats_table.IsSingleUnit]);
                if isfield(recording_stats_table, 'CellType')
                    recording_row.CellTypes = {unique(recording_stats_table.CellType)};
                end
                if isfield(recording_stats_table, 'ResponseType')
                    recording_row.ResponseTypes = {unique(recording_stats_table.ResponseType)};
                end
                group_stats_table = [group_stats_table; recording_row];
            end
        end
        
       if ~isempty(all_group_amplitudes)
            group_stats = calculate_unit_stats(all_group_amplitudes, all_group_spikes);
            stats_by_level.(groupName).summary = group_stats;
            
            % Plot group level
            plot_level_stats(all_group_amplitudes, group_stats, ...
                sprintf('%s_Group', groupName), save_path);
            
            % Save group table with metadata
            writetable(group_stats_table, fullfile(save_path, ...
                sprintf('%s_recordings_with_metadata.csv', groupName)));
            
            % Append to project level
            all_project_amplitudes = [all_project_amplitudes; all_group_amplitudes];
        end
    end
    
    % Calculate and store project level stats
    if ~isempty(all_project_amplitudes)
        project_stats = calculate_unit_stats(all_project_amplitudes);
        stats_by_level.summary = project_stats;
        
        % Plot project level
        plot_level_stats(all_project_amplitudes, project_stats, 'Project', save_path);
        
        % Create project-wide boxplot
        plot_project_boxplot(all_amplitudes, recording_labels, group_labels, save_path);
    end
end

%% Helper Functions

% Calculate Unit Stats
function stats = calculate_unit_stats(amplitudes)
    % Calculate basic statistics
    stats.n_spikes = length(amplitudes);
    stats.mean = mean(amplitudes);
    stats.median = median(amplitudes);
    stats.min = min(amplitudes);
    stats.max = max(amplitudes);
    stats.std = std(amplitudes);
    stats.std_error = stats.std / sqrt(stats.n_spikes);
    stats.range = stats.max - stats.min;
    
    % Test for normality using Shapiro-Wilk test
    [~, p_value] = swtest(amplitudes);
    is_normal = p_value > 0.05;
    
    % Calculate 95% CI based on distribution type
    alpha = 0.05;
    if is_normal
        % Normal distribution CI
        t_score = tinv(1-alpha/2, stats.n_spikes-1);
        stats.CI_lower = stats.mean - t_score * stats.std_error;
        stats.CI_upper = stats.mean + t_score * stats.std_error;
        stats.distribution = 'Normal';
    else
        % Poisson distribution CI
        n = stats.n_spikes;
        stats.CI_lower = 0.5 * chi2inv(alpha/2, 2*n);
        stats.CI_upper = 0.5 * chi2inv(1-alpha/2, 2*(n+1));
        stats.distribution = 'Poisson';
    end
end

% Shapiro-Wilks Test
function [H, pValue] = swtest(x)
    % Shapiro-Wilk test implementation for MATLAB
    % This is a simplified version - you may want to use the full implementation
    x = x(:);
    n = length(x);
    y = sort(x);
    
    % Calculate W statistic
    m = norminv((1:n)' / (n+1));
    C = 1/sqrt(m'*m) * m;
    w = (C'*y)^2 / ((y-mean(y))'*(y-mean(y)));
    
    % Calculate p-value (approximation)
    mu = -1.2725 + 1.0521 * log(n);
    sigma = 1.0308 - 0.26758 * log(n);
    z = (log(1-w) - mu) / sigma;
    pValue = 1 - normcdf(z);
    H = pValue < 0.05;
end

% Plot Distributions as Histograms
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
    title(sprintf('Amplitude Distribution - %s', level_name));
    legend('Amplitude Distribution', 'Mean', '95% CI');
    
    % Save figure
    savefig(fullfile(save_path, sprintf('%s_amplitude_distribution.fig', level_name)));
    saveas(gcf, fullfile(save_path, sprintf('%s_amplitude_distribution.png', level_name)));
    close(gcf);
end

% Plot All Recording distributions as boxplots
function plot_project_boxplot(amplitudes, recording_labels, group_labels, save_path)
    figure('Name', 'Project-wide Recording Comparisons', 'Position', [100 100 1200 600]);
    
    % Get unique groups and assign colors
    unique_groups = unique(group_labels);
    colors = lines(length(unique_groups));
    color_map = containers.Map(unique_groups, num2cell(colors, 2));
    
    % Create boxplot
    [g, recording_names] = findgroups(recording_labels);
    boxplot(amplitudes, g, 'Labels', recording_names, 'Orientation', 'vertical');
    
    % Customize boxplot colors by group
    h = findobj(gca, 'Tag', 'Box');
    for j = 1:length(recording_names)
        % Find group for this recording
        recording_group = group_labels{find(strcmp(recording_labels, recording_names{j}), 1)};
        patch(get(h(end-j+1), 'XData'), get(h(end-j+1), 'YData'), ...
            color_map(recording_group), 'FaceAlpha', 0.5);
    end
    
    % Customize plot
    xlabel('Recordings');
    ylabel('Amplitude (µV)');
    title('Amplitude Distribution Across Recordings');
    
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