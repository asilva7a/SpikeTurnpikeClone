function plot_group_PSTH(cellDataStruct, params)
    % Define a colormap for different recordings
    colormapList = lines(10);  % Generate 10 unique colors
    responseTypes = {'Increased', 'Decreased', 'No Change'};
    groupNames = fieldnames(cellDataStruct);
    
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        numRecordings = length(recordings);
        recordingColors = colormapList(1:numRecordings, :);
        
        % Create figure with 2 rows: individual PSTHs and mean PSTHs
        fig = figure('Name', ['PSTHs - ', groupName], ...
                    'Position', [100 100 1500 800], ...
                    'NumberTitle', 'off');
        
        % First row: Individual PSTHs
        for rt = 1:length(responseTypes)
            subplot(2, 3, rt);
            plot_individual_PSTHs(cellDataStruct, groupName, ...
                                responseTypes{rt}, recordings, recordingColors, params);
            title([groupName, ' - ', responseTypes{rt}, ' Individual']);
        end
        
        % Second row: Mean PSTHs
        for rt = 1:length(responseTypes)
            subplot(2, 3, rt + 3);
            plot_mean_PSTH(cellDataStruct, groupName, ...
                          responseTypes{rt}, recordings, recordingColors, params);
            title([groupName, ' - ', responseTypes{rt}, ' Mean']);
        end
        
        % Add common xlabel and ylabel
        han = axes(fig, 'visible', 'off');
        han.XLabel.Visible = 'on';
        han.YLabel.Visible = 'on';
        xlabel(han, 'Time (s)', 'FontSize', 12);
        ylabel(han, 'Firing Rate (Hz)', 'FontSize', 12);
    end
end

function plot_individual_PSTHs(cellDataStruct, groupName, responseType, recordings, recordingColors, params)
    hold on;
    unitsPlotted = false;
    
    for r = 1:length(recordings)
        recordingName = recordings{r};
        units = fieldnames(cellDataStruct.(groupName).(recordingName));
        
        for u = 1:length(units)
            unitID = units{u};
            unitData = cellDataStruct.(groupName).(recordingName).(unitID);
            
            if ~isValidUnit(unitData, responseType)
                continue;
            end
            
            % Plot smoothed PSTH
            smoothedPSTH = smoothdata(unitData.PSTH_Label, 'gaussian', params.smoothingWindow);
            plot(smoothedPSTH, 'Color', [recordingColors(r,:) 0.3], 'LineWidth', 0.5);
            unitsPlotted = true;
        end
    end
    
    if ~unitsPlotted
        text(0.5, 0.5, 'No units', 'HorizontalAlignment', 'center', ...
             'Units', 'normalized', 'FontSize', 12);
    end
    
    % Add treatment time line
    if isfield(params, 'treatmentTime')
        xline(params.treatmentTime, '--k', 'LineWidth', 1.5);
    end
    
    grid on;
    hold off;
end

function plot_mean_PSTH(cellDataStruct, groupName, responseType, recordings, recordingColors, params)
    hold on;
    allPSTHs = [];
    
    % Collect all PSTHs for this response type
    for r = 1:length(recordings)
        recordingPSTHs = [];
        units = fieldnames(cellDataStruct.(groupName).(recordings{r}));
        
        for u = 1:length(units)
            unitData = cellDataStruct.(groupName).(recordings{r}).(units{u});
            
            if ~isValidUnit(unitData, responseType)
                continue;
            end
            
            smoothedPSTH = smoothdata(unitData.PSTH_Label, 'gaussian', params.smoothingWindow);
            recordingPSTHs(end+1,:) = smoothedPSTH;
        end
        
        % Plot recording mean if units exist
        if ~isempty(recordingPSTHs)
            meanPSTH = mean(recordingPSTHs, 1);
            semPSTH = std(recordingPSTHs, [], 1) / sqrt(size(recordingPSTHs, 1));
            
            % Plot shaded error bars
            fill([1:length(meanPSTH), fliplr(1:length(meanPSTH))], ...
                 [meanPSTH + semPSTH, fliplr(meanPSTH - semPSTH)], ...
                 recordingColors(r,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            
            % Plot mean line
            plot(meanPSTH, 'Color', recordingColors(r,:), 'LineWidth', 2);
            
            allPSTHs = [allPSTHs; recordingPSTHs];
        end
    end
    
    % Plot overall mean if any units exist
    if ~isempty(allPSTHs)
        overallMean = mean(allPSTHs, 1);
        overallSEM = std(allPSTHs, [], 1) / sqrt(size(allPSTHs, 1));
        plot(overallMean, 'k', 'LineWidth', 2);
        
        % Add unit count to title
        title([groupName, ' - ', responseType, sprintf(' (n=%d)', size(allPSTHs,1))]);
    else
        text(0.5, 0.5, 'No units', 'HorizontalAlignment', 'center', ...
             'Units', 'normalized', 'FontSize', 12);
    end
    
    % Add treatment time line
    if isfield(params, 'treatmentTime')
        xline(params.treatmentTime, '--k', 'LineWidth', 1.5);
    end
    
    grid on;
    hold off;
end

function isValid = isValidUnit(unitData, responseType)
    isValid = isfield(unitData, 'ResponseType') && ...
              isfield(unitData, 'PSTH_Label') && ...
              strcmp(unitData.ResponseType, responseType);
end



