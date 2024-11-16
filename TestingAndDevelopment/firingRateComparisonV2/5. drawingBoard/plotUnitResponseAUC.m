function plotAUCResponse(cellDataStruct, figureFolder)
    % Process each experimental group
    experimentalGroups = {'Emx', 'Pvalb', 'Control'};
    
    for g = 1:length(experimentalGroups)
        groupName = experimentalGroups{g};
        if ~isfield(cellDataStruct, groupName)
            continue;
        end
        
        % Process each recording
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Get time vector from first unit
            firstUnit = cellDataStruct.(groupName).(recordingName).(units{1});
            timeVector = firstUnit.binEdges(1:end-1) + firstUnit.binWidth/2;
            
            % Define analysis windows
            preWindow = [300 1860];   % 5-31 minutes
            postWindow = [1860 3420]; % 31-57 minutes
            
            % Process each unit
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(units{u});
                
                if ~isfield(unitData, 'psthSmoothed')
                    continue;
                end
                
                % Calculate AUC for pre and post periods
                preIdx = timeVector >= preWindow(1) & timeVector <= preWindow(2);
                postIdx = timeVector >= postWindow(1) & timeVector <= postWindow(2);
                
                preAUC = mean(unitData.psthSmoothed(preIdx));
                postAUC = mean(unitData.psthSmoothed(postIdx));
                
                % Calculate percent change
                percentChange = ((postAUC - preAUC) / preAUC) * 100;
                
                % Determine response type
                if percentChange > 20
                    responseType = 'Enhanced';
                    color = [1 0 1]; % Magenta
                elseif percentChange < -20
                    responseType = 'Dampened';
                    color = [0 1 1]; % Cyan
                else
                    responseType = 'No Change';
                    color = [1 1 0]; % Yellow
                end
                
                % Create figure
                fig = figure('Position', [100 100 1000 400], 'Visible', 'off');
                
                % Plot PSTH
                plot(timeVector, unitData.psthSmoothed, 'Color', color, 'LineWidth', 1.5);
                hold on;
                
                % Add treatment line
                xline(1860, '--k', 'LineWidth', 1.5);
                
                % Shade analysis windows
                yLim = ylim;
                patch([preWindow(1) preWindow(2) preWindow(2) preWindow(1)], ...
                      [yLim(1) yLim(1) yLim(2) yLim(2)], ...
                      [0.8 0.8 0.8], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                patch([postWindow(1) postWindow(2) postWindow(2) postWindow(1)], ...
                      [yLim(1) yLim(1) yLim(2) yLim(2)], ...
                      [0.8 0.8 0.8], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                
                % Formatting
                xlabel('Time (s)');
                ylabel('Firing Rate (Hz)');
                grid on;
                set(gca, 'Layer', 'top', 'GridAlpha', 0.15, 'FontSize', 10);
                
                % Add title and metadata
                title({sprintf('%s %s Unit %s', groupName, recordingName, unitID), ...
                       sprintf('Response: %s (%.1f%% change)', responseType, percentChange)});
                
                % Add legend with AUC values
                legend({sprintf(['Pre AUC: %.2f Hz\nPost AUC: %.2f Hz\n' ...
                               'Analysis Windows:\nPre: %d-%d s\nPost: %d-%d s'], ...
                               preAUC, postAUC, ...
                               preWindow(1), preWindow(2), ...
                               postWindow(1), postWindow(2))}, ...
                       'Location', 'northeastoutside', ...
                       'FontSize', 10);
                
                % Save directly to unit's directory
                saveDir = fullfile(figureFolder, groupName, recordingName, unitID);
                
                savefig(fig, fullfile(saveDir, 'AUC_Analysis.fig'));
                saveas(fig, fullfile(saveDir, 'AUC_Analysis.png'));
                close(fig);
            end
        end
    end
end

