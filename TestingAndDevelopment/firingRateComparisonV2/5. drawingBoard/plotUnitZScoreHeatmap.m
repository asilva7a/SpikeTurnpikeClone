function plotUnitZScoreHeatmap(cellDataStruct, figureFolder, varargin)
    % Parse optional parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct');
    addRequired(p, 'figureFolder');
    addParameter(p, 'UnitFilter', 'both', @ischar);
    addParameter(p, 'OutlierFilter', true, @islogical);
    addParameter(p, 'BoxCarWindow', 10, @isnumeric);
    addParameter(p, 'ColorLimits', [-2 2], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));
    addParameter(p, 'FontSize', 10, @isnumeric);
    parse(p, cellDataStruct, figureFolder, varargin{:});
    opts = p.Results;

    % Define color scheme for response types and subtypes
    colorMap = containers.Map();
    colorMap('Increased_Strong') = [0.8 0 0];        % Deep red
    colorMap('Increased_Moderate') = [1 0.2 0.2];    % Bright red
    colorMap('Increased_Variable') = [1 0.4 0.4];    % Light red
    colorMap('Decreased_Strong') = [0 0 0.8];        % Deep blue
    colorMap('Decreased_Moderate') = [0 0.2 1];      % Bright blue
    colorMap('Decreased_Variable') = [0.4 0.4 1];    % Light blue
    colorMap('Changed_Weak') = [0.5 0 0.5];         % Purple
    colorMap('No_Change_None') = [0.4 0.4 0.4];     % Gray

    % Initialize storage for EMX and PVALB groups
    groupsToPlot = {'Emx', 'Pvalb'};
    
    % Pre-initialize combinedData structure
    combinedData = struct();
    combinedData.PSTHs = [];
    combinedData.CohensD = [];
    combinedData.Labels = {};
    combinedData.Colors = [];
    combinedData.GroupLabels = {};
    
    % Process selected groups
    for g = 1:length(groupsToPlot)
        groupName = groupsToPlot{g};
        if ~isfield(cellDataStruct, groupName)
            warning('Group %s not found in data structure', groupName);
            continue;
        end
        
        % Initialize arrays for this group
        PSTHs = [];
        CohensD = [];
        Labels = {};
        Colors = [];
        GroupLabels = {};
        
        % Process recordings in this group
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Check unit validity
                if ~isValidUnit(unitData, opts.UnitFilter, opts.OutlierFilter)
                    continue;
                end
                
                if isfield(unitData, 'psthZScore') && isfield(unitData, 'responseMetrics')
                    % Get response type and subtype
                    responseType = strrep(unitData.responseType, ' ', '_');
                    subtype = unitData.responseMetrics.subtype;
                    colorKey = sprintf('%s_%s', responseType, subtype);
                    
                    % Store data
                    PSTHs = [PSTHs; smoothdata(unitData.psthZScore, 'movmean', opts.BoxCarWindow)];
                    CohensD = [CohensD; unitData.responseMetrics.stats.cohens_d];
                    Labels = [Labels; unitID];
                    GroupLabels = [GroupLabels; groupName];
                    
                    % Get color
                    if colorMap.isKey(colorKey)
                        Colors = [Colors; colorMap(colorKey)];
                    else
                        Colors = [Colors; [0.7 0.7 0.7]];
                    end
                end
            end
        end
        
        % Sort by Cohen's d within group
        if ~isempty(CohensD)
            [~, sortIdx] = sort(CohensD, 'descend');
            
            % Concatenate sorted data
            combinedData.PSTHs = [combinedData.PSTHs; PSTHs(sortIdx,:)];
            combinedData.CohensD = [combinedData.CohensD; CohensD(sortIdx)];
            combinedData.Labels = [combinedData.Labels; Labels(sortIdx)];
            combinedData.Colors = [combinedData.Colors; Colors(sortIdx,:)];
            combinedData.GroupLabels = [combinedData.GroupLabels; GroupLabels(sortIdx)];
        end
    end
    
    % Check if we have any data to plot
    if isempty(combinedData.PSTHs)
        error('No valid data found for plotting');
    end
    
    % Create figure
    fig = figure('Position', [100 100 1500 800]);
    t = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % Plot combined heatmap
    nexttile
    if isempty(opts.ColorLimits)
        imagesc(combinedData.PSTHs);
    else
        imagesc(combinedData.PSTHs, opts.ColorLimits);
    end
    colormap(redblue(256));
    c = colorbar;
    c.Label.String = 'Z-Score';
    
    % Add group separation line
    hold on;
    emxCount = sum(strcmp(combinedData.GroupLabels, 'Emx'));
    yline(emxCount + 0.5, 'w-', 'LineWidth', 2);
    
    % Add treatment time line
    xline(1860/5, '--w', 'LineWidth', 1);
    
    % Add group labels
    yticks([emxCount/2, emxCount + (length(combinedData.GroupLabels) - emxCount)/2]);
    yticklabels({'EMX', 'PVALB'});
    
    xlabel('Time (ms)', 'FontSize', opts.FontSize);
    ylabel('Units (Ranked by Cohen''s d)', 'FontSize', opts.FontSize);
    title('Z-Score Changes', 'FontSize', opts.FontSize + 2);
    
    % Plot combined Cohen's d values
    nexttile
    for i = 1:length(combinedData.CohensD)
        barh(i, combinedData.CohensD(i), 'FaceColor', combinedData.Colors(i,:), 'EdgeColor', 'none');
        hold on;
    end
    hold off;
    
    % Add group separation line
    hold on;
    yline(emxCount + 0.5, 'k-', 'LineWidth', 2);
    
    xlabel('Cohen''s d', 'FontSize', opts.FontSize);
    ylabel('Units (Ranked)', 'FontSize', opts.FontSize);
    title('Effect Size', 'FontSize', opts.FontSize + 2);
    
    % Add group labels
    yticks([emxCount/2, emxCount + (length(combinedData.GroupLabels) - emxCount)/2]);
    yticklabels({'EMX', 'PVALB'});
    
    % Add overall title
    title(t, 'Population Z-Score Response: EMX vs PVALB', 'FontSize', opts.FontSize + 4);
    
    % Save figure
    saveDir = fullfile(figureFolder, '0. expFigures');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    
    timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
    filename = sprintf('ZScoreHeatmap_EMXvsPVALB_BoxCar%ds_%s', opts.BoxCarWindow, timestamp);
    savefig(fig, fullfile(saveDir, [filename '.fig']));
    saveas(fig, fullfile(saveDir, [filename '.png']));
    close(fig);
end

% Helper functions remain the same
function isValid = isValidUnit(unitData, unitFilter, outlierFilter)
    % Check outlier status
    if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
        isValid = false;
        return;
    end
    
    % Check unit type
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    if strcmp(unitFilter, 'single') && ~isSingleUnit || ...
       strcmp(unitFilter, 'multi') && isSingleUnit
        isValid = false;
        return;
    end
    
    isValid = true;
end

function c = redblue(m)
    % Custom red-blue colormap
    if nargin < 1
        m = 256;
    end
    
    bottom = [0 0 1];
    middle = [1 1 1];
    top = [1 0 0];
    
    % Create color segments
    bottom_half = interp1([0 1], [bottom; middle], linspace(0,1,ceil(m/2)));
    top_half = interp1([0 1], [middle; top], linspace(0,1,floor(m/2)));
    
    c = [bottom_half; top_half(2:end,:)];
end