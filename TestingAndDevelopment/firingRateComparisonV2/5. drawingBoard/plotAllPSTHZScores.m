function plotAllPSTHZScores(cellDataStruct)
    % Initialize storage vectors
    zscores_all = [];         % [time x units]
    zscores_enhanced = [];    % [time x units]
    stats_all = [];          % Store statistics
    stats_enhanced = [];     % Store statistics for enhanced units
    groupsLabels_all = {};
    mouseLabels_all = {};
    cellID_Labels_all = {};
    groupsLabels_enhanced = {};
    mouseLabels_enhanced = {};
    cellID_Labels_enhanced = {};
    
    % Get data from structure
    groupNames = fieldnames(cellDataStruct);
    
    fprintf('\nEnhanced Units Found:\n');
    fprintf('-------------------\n');
    
    % Get first unit's time vector for plotting
    firstGroup = groupNames{1};
    firstRecording = fieldnames(cellDataStruct.(firstGroup)){1};
    firstUnit = fieldnames(cellDataStruct.(firstGroup).(firstRecording)){1};
    timeVector = cellDataStruct.(firstGroup).(firstRecording).(firstUnit).binEdges(1:end-1) + ...
                cellDataStruct.(firstGroup).(firstRecording).(firstUnit).binWidth/2;
    
    % Collect zscores
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Check if unit has required fields
                if ~isfield(unitData, 'psthZScore') || ...
                   ~isfield(unitData, 'psthZScoreStats') || ...
                   ~isfield(unitData, 'responseType')
                    continue;
                end
                
                % Get zscore and stats
                zscore = unitData.psthZScore;
                stats = unitData.psthZScoreStats;
                
                % Store in all units
                zscores_all = [zscores_all, zscore'];
                stats_all = [stats_all; stats];
                groupsLabels_all{end+1,1} = groupName;
                mouseLabels_all{end+1,1} = recordingName;
                cellID_Labels_all{end+1,1} = unitID;
                
                % Check if enhanced
                if strcmp(strrep(unitData.responseType, ' ', ''), 'Increased')
                    fprintf('Group: %s | Recording: %s | Unit: %s\n', ...
                        groupName, recordingName, unitID);
                    
                    zscores_enhanced = [zscores_enhanced, zscore'];
                    stats_enhanced = [stats_enhanced; stats];
                    groupsLabels_enhanced{end+1,1} = groupName;
                    mouseLabels_enhanced{end+1,1} = recordingName;
                    cellID_Labels_enhanced{end+1,1} = unitID;
                end
            end
        end
    end

    % Print summary
    fprintf('\nSummary:\n');
    fprintf('Total units: %d\n', size(zscores_all, 2));
    fprintf('Enhanced units: %d\n\n', size(zscores_enhanced, 2));
    
    % Plotting
    figure('Position', [100 100 1200 1000]);
    T = tiledlayout(3,1);
    
    % Top panel: Enhanced units only
    nexttile(T, [1 1]);
    hold on;
    for unitInd = 1:size(zscores_enhanced,2)
        p = plot(timeVector, zscores_enhanced(:,unitInd), 'Color', [1 0 0, 0.2]);
        p.DataTipTemplate.DataTipRows(1:2) = [dataTipTextRow("Rec:", repmat(mouseLabels_enhanced(unitInd),length(timeVector),1)),...
                                             dataTipTextRow("Cell:", repmat(cellID_Labels_enhanced(unitInd),length(timeVector),1))];
        p.DataTipTemplate.set('Interpreter','none');
    end
    
    % Plot mean enhanced zscore
    if ~isempty(zscores_enhanced)
        meanZScore_enhanced = mean(zscores_enhanced,2);
        plot(timeVector, meanZScore_enhanced, 'Color', [1 0 0], 'LineWidth', 2);
    end
    title(sprintf('Enhanced Units Z-Scores (n=%d)', size(zscores_enhanced,2)));
    xline(2000, '--k'); % Treatment time marker
    ylabel('Z-Score');
    hold off;
    
    % Middle panel: All units
    nexttile(T, [1 1]);
    hold on;
    for unitInd = 1:size(zscores_all,2)
        p = plot(timeVector, zscores_all(:,unitInd), 'Color', [0.7 0.7 0.7 0.3]);
        p.DataTipTemplate.DataTipRows(1:2) = [dataTipTextRow("Rec:", repmat(mouseLabels_all(unitInd),length(timeVector),1)),...
                                             dataTipTextRow("Cell:", repmat(cellID_Labels_all(unitInd),length(timeVector),1))];
        p.DataTipTemplate.set('Interpreter','none');
    end
    
    meanZScore_all = mean(zscores_all,2);
    plot(timeVector, meanZScore_all, 'Color', [0.6 0.6 0.6], 'LineWidth', 2);
    title(sprintf('All Units Z-Scores (n=%d)', size(zscores_all,2)));
    xline(2000, '--k'); % Treatment time marker
    ylabel('Z-Score');
    hold off;
    
    % Bottom panel: Statistics
    nexttile(T, [1 1]);
    hold on;
    
    % Calculate and plot statistics
    if ~isempty(stats_all)
        % Create box plot or violin plot of baseline vs post-treatment statistics
        baseline_stats = arrayfun(@(x) x.baseline.mean, stats_all);
        post_stats = arrayfun(@(x) x.postTreatment.mean, stats_all);
        
        boxplot([baseline_stats, post_stats], ...
                'Labels', {'Baseline', 'Post-Treatment'}, ...
                'Colors', [0.6 0.6 0.6]);
        
        % Add individual points
        scatter(ones(size(baseline_stats)) + (rand(size(baseline_stats))-0.5)*0.2, baseline_stats, 20, [0.7 0.7 0.7], 'filled', 'MarkerFaceAlpha', 0.3);
        scatter(2*ones(size(post_stats)) + (rand(size(post_stats))-0.5)*0.2, post_stats, 20, [0.7 0.7 0.7], 'filled', 'MarkerFaceAlpha', 0.3);
    end
    
    title('Population Statistics');
    ylabel('Z-Score');
    hold off;
    
    % Add overall title and labels
    title(T, 'Population Z-Score Analysis', 'FontSize', 12);
    xlabel(T, 'Time (ms)', 'FontSize', 10);
    
    % Add grid to all plots
    for i = 1:3
        nexttile(i);
        grid on;
        set(gca, 'Layer', 'top', 'GridAlpha', 0.15);
    end

    % Save figure
    try
        timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
        fileName = sprintf('allUnitsZScores_%s', timeStamp);
        
        fig = gcf;
        
        savefig(fig, fullfile(pwd, [fileName '.fig']));
        print(fig, fullfile(pwd, [fileName '.tif']), '-dtiff', '-r300');
        
        close(fig);
    catch ME
        warning('Save:Error', 'Error saving figure: %s', ME.message);
    end
end
