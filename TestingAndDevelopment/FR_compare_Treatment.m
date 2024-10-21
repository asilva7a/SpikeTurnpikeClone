function data_table_FR = FR_compare_Treatment(all_data, cell_types, binSize, plot_points, moment, period)
    % Plot and compare ISI coefficient of variation (CV) between groups for periods before and after a specified moment.
    %
    % INPUTS
    % - all_data
    % - cell_types: cell array of cell types to plot. e.g., {'MSN','TAN'}
    % - binSize: size of bins (seconds) to calculate FRs. The maximum of those
    %            binned FRs will be the final saved FR of the unit. If 0, the
    %            whole-recording FR is used instead.
    % - plot_points: 0 to only plot bars (+/- SEM), 1 to plot points on top.
    %       Useful to show the distribution.
    % - moment: the specified moment (seconds) around which to analyze FRs.
    % - period: the period (seconds) before and after the moment to consider for analysis.
    
    groupNames = fieldnames(all_data);
    
    groupsVec = {};
    cellTypesVec = {};
    FRs_vec = [];
    timePeriodVec = {}; % To store time period information ('Before', 'After')
    
    for groupNum = 1:length(groupNames)
        groupName = groupNames{groupNum};
    
        mouseNames = fieldnames(all_data.(groupName));
    
        for mouseNum = 1:length(mouseNames)
            mouseName = mouseNames{mouseNum};
    
            cellIDs = fieldnames(all_data.(groupName).(mouseName));
    
            for cellID_num = 1:length(cellIDs)
                cellID = cellIDs{cellID_num};
    
                thisCellType = all_data.(groupName).(mouseName).(cellID).Cell_Type;
                isSingleUnit = all_data.(groupName).(mouseName).(cellID).IsSingleUnit;
                if any(strcmp(cell_types, thisCellType)) && isSingleUnit
                    % Calculate FR for the period before the moment
                    spikeTimes = all_data.(groupName).(mouseName).(cellID).SpikeTimes_all / all_data.(groupName).(mouseName).(cellID).Sampling_Frequency;
                    
                    % Before the moment
                    startTime = max(0, moment - period);
                    endTime = moment;
                    intervalBounds = startTime:binSize:endTime;
                    binned_FRs_vec_before = [];
                    for ii = 1:length(intervalBounds)-1
                        n_spikes = length(spikeTimes((spikeTimes >= intervalBounds(ii))&(spikeTimes <= intervalBounds(ii+1))));
                        binned_FRs_vec_before(end+1,1) = n_spikes / binSize;
                    end
                    if ~isempty(binned_FRs_vec_before)
                        FRs_vec(end+1,1) = max(binned_FRs_vec_before);
                        groupsVec{end+1,1} = groupName;
                        cellTypesVec{end+1,1} = thisCellType;
                        timePeriodVec{end+1,1} = 'Before';
                    end
    
                    % After the moment
                    startTime = moment;
                    endTime = min(all_data.(groupName).(mouseName).(cellID).Recording_Duration, moment + period);
                    intervalBounds = startTime:binSize:endTime;
                    binned_FRs_vec_after = [];
                    for ii = 1:length(intervalBounds)-1
                        n_spikes = length(spikeTimes((spikeTimes >= intervalBounds(ii))&(spikeTimes <= intervalBounds(ii+1))));
                        binned_FRs_vec_after(end+1,1) = n_spikes / binSize;
                    end
                    if ~isempty(binned_FRs_vec_after)
                        FRs_vec(end+1,1) = max(binned_FRs_vec_after);
                        groupsVec{end+1,1} = groupName;
                        cellTypesVec{end+1,1} = thisCellType;
                        timePeriodVec{end+1,1} = 'After';
                    end
                end
            end
        end
    end
    
    %% Remove outliers (optional, commented out)
    % FRs_vec_new = [];
    % groupsVec_new = {};
    % cellTypesVec_new = {};
    % 
    % for groupNum = 1:length(groupNames)
    %     groupName = groupNames{groupNum};
    %     for cell_type_ind = 1:length(cell_types)
    %         cell_type_name = cell_types{cell_type_ind};
    % 
    %         FRs_vec_sub = FRs_vec(strcmp(groupsVec,groupName) & strcmp(cellTypesVec,cell_types{cell_type_ind}),1);
    %         FRs_vec_sub = rmoutliers(FRs_vec_sub);
    % 
    %         groupsVec_sub = groupsVec(strcmp(groupsVec,groupName),1);
    %         groupsVec_sub = groupsVec_sub(1:length(FRs_vec_sub),1);
    % 
    %         cellTypesVec_sub = cellTypesVec(strcmp(cellTypesVec,cell_type_name),1);
    %         cellTypesVec_sub = cellTypesVec_sub(1:length(FRs_vec_sub),1);
    % 
    %         FRs_vec_new = [FRs_vec_new; FRs_vec_sub];
    %         groupsVec_new = cat(1, groupsVec_new, groupsVec_sub);
    %         cellTypesVec_new = cat(1, cellTypesVec_new, cellTypesVec_sub);
    %     end
    % end
    % FRs_vec = FRs_vec_new;
    % groupsVec = groupsVec_new;
    % cellTypesVec = cellTypesVec_new;
    
    %% Plotting 
    figure;
    g = gramm('x',timePeriodVec, 'y',FRs_vec, 'color',groupsVec);
    g.facet_grid([],cellTypesVec, "scale","independent");
    g.stat_summary('type','sem', 'geom',{'bar','black_errorbar'}, 'width',0.6, 'dodge',0.8, 'setylim',true);
    g.set_names('x','Time Period', 'y','Firing Rate (Hz)', 'Color','Group', 'Column','Cell Type');
    g.no_legend;
    g.draw();
    
    if plot_points
        g.update('x',timePeriodVec, 'y',FRs_vec, "color",groupsVec);
        g.geom_point('dodge',0.8);
        g.set_color_options('lightness',40);
        g.set_point_options("markers","^", "base_size",3);
        g.no_legend;
        g.draw;
    end
   
    
    %% Make data table to export for stats
    data_table_FR = table(groupsVec, cellTypesVec, timePeriodVec, FRs_vec, 'VariableNames',{'Group','CellType','TimePeriod','FR'});
    
    end
    