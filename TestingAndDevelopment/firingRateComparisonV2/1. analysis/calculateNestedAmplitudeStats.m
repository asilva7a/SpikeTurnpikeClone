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
        group_summary = table();
        
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
                    % Store unit metadata
                    unit_row = table();
                    unit_row.UnitID = {unitID};
                    unit_row.Amplitude = unitData.Amplitude;
                    if isfield(unitData, 'CellType')
                        unit_row.CellType = {unitData.CellType};
                    end
                    if isfield(unitData, 'IsSingleUnit')
                        unit_row.IsSingleUnit = unitData.IsSingleUnit;
                    end
                    unit_metadata_table = [unit_metadata_table; unit_row];
                    
                    % Append amplitude for recording level analysis
                    all_recording_amplitudes = [all_recording_amplitudes; unitData.Amplitude];
                    
                    % Store data for project-wide boxplot
                    all_amplitudes = [all_amplitudes; unitData.Amplitude];
                    recording_labels = [recording_labels; {recordingName}];
                    group_labels = [group_labels; {groupName}];
                end
            end
            
            % Calculate recording level stats
            if ~isempty(all_recording_amplitudes)
                % Calculate summary stats
                recording_summary = table();
                recording_summary.Recording = {recordingName};
                recording_summary.TotalUnits = height(unit_metadata_table);
                recording_summary.SingleUnits = sum([unit_metadata_table.IsSingleUnit]);
                recording_summary.RSUnits = sum(strcmp(unit_metadata_table.CellType, 'RS'));
                recording_summary.FSUnits = sum(strcmp(unit_metadata_table.CellType, 'FS'));
                
                % Calculate amplitude stats
                recording_stats = calculate_unit_stats(all_recording_amplitudes, 'recording');
                stats_by_level.(groupName).(recordingName).summary = recording_stats;
                
                % Add amplitude stats to summary
                recording_summary.MeanAmplitude = recording_stats.mean;
                recording_summary.MedianAmplitude = recording_stats.median;
                recording_summary.StdAmplitude = recording_stats.std;
                
                % Plot recording level
                plot_level_stats(all_recording_amplitudes, recording_stats, ...
                    sprintf('%s_%s_Recording', groupName, recordingName), save_path);
                
                % Save tables
                writetable(unit_metadata_table, fullfile(save_path, ...
                    sprintf('%s_%s_units_metadata.csv', groupName, recordingName)));
                writetable(recording_summary, fullfile(save_path, ...
                    sprintf('%s_%s_recording_summary.csv', groupName, recordingName)));
                
                % Append to group level
                all_group_amplitudes = [all_group_amplitudes; all_recording_amplitudes];
                group_summary = [group_summary; recording_summary];
            end
        end
        
        % Calculate group level stats
        if ~isempty(all_group_amplitudes)
            % Calculate group stats
            group_stats = calculate_unit_stats(all_group_amplitudes, 'group');
            stats_by_level.(groupName).summary = group_stats;
            
            % Create group summary
            group_total = table();
            group_total.Group = {groupName};
            group_total.TotalRecordings = height(group_summary);
            group_total.TotalUnits = sum(group_summary.TotalUnits);
            group_total.SingleUnits = sum(group_summary.SingleUnits);
            group_total.RSUnits = sum(group_summary.RSUnits);
            group_total.FSUnits = sum(group_summary.FSUnits);
            group_total.MeanAmplitude = group_stats.mean;
            group_total.MedianAmplitude = group_stats.median;
            group_total.StdAmplitude = group_stats.std;
            
            % Plot group level
            plot_level_stats(all_group_amplitudes, group_stats, ...
                sprintf('%s_Group', groupName), save_path);
            
            % Save group summary
            writetable(group_total, fullfile(save_path, ...
                sprintf('%s_group_summary.csv', groupName)));
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
