function plotAllMeanWaveforms(cellDataStruct)
    % Initialize storage vectors
    waveforms_all = []; % [samples x units]
    waveforms_enhanced = []; % [samples x units]
    groupsLabels_all = {};
    mouseLabels_all = {};
    cellID_Labels_all = {};
    groupsLabels_enhanced = {};
    mouseLabels_enhanced = {};
    cellID_Labels_enhanced = {};
    
    % Get data from structure
    groupNames = fieldnames(cellDataStruct);
    
    % Collect waveforms
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
                if ~isfield(unitData, 'NormalizedTemplateWaveform') || ...
                   ~isfield(unitData, 'IsSingleUnit') || ...
                   ~isfield(unitData, 'responseType')
                    continue;
                end
                
                % Only process single units
                if ~unitData.IsSingleUnit
                    continue;
                end
                
                % Get waveform
                waveform = unitData.NormalizedTemplateWaveform;
                
                % Store in all units
                waveforms_all = [waveforms_all, waveform];
                groupsLabels_all{end+1,1} = groupName;
                mouseLabels_all{end+1,1} = recordingName;
                cellID_Labels_all{end+1,1} = unitID;
                
                % Check if enhanced (Increased response type) and store separately
                if isfield(unitData, 'responseType') && ...
                   strcmp(strrep(unitData.responseType, ' ', ''), 'Increased')  % Matches exact response type
                    waveforms_enhanced = [waveforms_enhanced, waveform];
                    groupsLabels_enhanced{end+1,1} = groupName;
                    mouseLabels_enhanced{end+1,1} = recordingName;
                    cellID_Labels_enhanced{end+1,1} = unitID;
                end
            end
        end
    end
    
    % Plotting
    figure('Position', [100 100 1000 800]);
    T = tiledlayout(2,1);
    
    % Top panel: Enhanced units only
    nexttile(T);
    hold on;
    for unitInd = 1:size(waveforms_enhanced,2)
        p = plot(waveforms_enhanced(:,unitInd), 'Color', [1 0 1 0.3]); % Magenta for enhanced
        
        % Data tips for unit identification
        p.DataTipTemplate.DataTipRows(1:2) = [dataTipTextRow("Rec:", repmat(mouseLabels_enhanced(unitInd),size(waveforms_enhanced,1))),...
            dataTipTextRow("Cell:", repmat(cellID_Labels_enhanced(unitInd),size(waveforms_enhanced,1)))];
        p.DataTipTemplate.set('Interpreter','none');
    end
    
    % Plot mean enhanced waveform
    if ~isempty(waveforms_enhanced)
        meanWF_enhanced = mean(waveforms_enhanced,2);
        plot(meanWF_enhanced, 'Color', [1 0 1], 'LineWidth', 2);
    end
    title(sprintf('Enhanced Units Only (n=%d)', size(waveforms_enhanced,2)));
    hold off;
    
    % Bottom panel: All units
    nexttile(T);
    hold on;
    for unitInd = 1:size(waveforms_all,2)
        p = plot(waveforms_all(:,unitInd), 'Color', [0.7 0.7 0.7 0.3]);
        
        % Data tips for unit identification
        p.DataTipTemplate.DataTipRows(1:2) = [dataTipTextRow("Rec:", repmat(mouseLabels_all(unitInd),size(waveforms_all,1))),...
            dataTipTextRow("Cell:", repmat(cellID_Labels_all(unitInd),size(waveforms_all,1)))];
        p.DataTipTemplate.set('Interpreter','none');
    end
    
    % Plot mean of all waveforms
    meanWF_all = mean(waveforms_all,2);
    plot(meanWF_all, 'Color', 'k', 'LineWidth', 2);
    title(sprintf('All Units (n=%d)', size(waveforms_all,2)));
    hold off;
    
    % Add overall title
    title(T, 'Population Waveform Analysis', 'FontSize', 12);
    
    % Add common labels
    xlabel(T, 'Samples', 'FontSize', 10);
    ylabel(T, 'Normalized Amplitude', 'FontSize', 10);
    
    % Add grid to both plots
    for i = 1:2
        nexttile(i);
        grid on;
        set(gca, 'Layer', 'top', 'GridAlpha', 0.15);
    end
end
