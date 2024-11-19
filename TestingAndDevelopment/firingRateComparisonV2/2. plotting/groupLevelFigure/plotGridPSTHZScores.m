function plotGridPSTHZScores(cellDataStruct, ~)
    % Define more distinct color scheme for response types and subtypes
    colorMap = containers.Map();
    
    % Increased responses - Red spectrum
    colorMap('Increased_Strong') = [0.8 0 0];        % Deep red
    colorMap('Increased_Moderate') = [1 0.2 0.2];    % Bright red
    colorMap('Increased_Variable') = [1 0.4 0.4];    % Light red
    
    % Decreased responses - Blue spectrum
    colorMap('Decreased_Strong') = [0 0 0.8];        % Deep blue
    colorMap('Decreased_Moderate') = [0 0.2 1];      % Bright blue
    colorMap('Decreased_Variable') = [0.4 0.4 1];    % Light blue
    
    % Other responses
    colorMap('Changed_Weak') = [0.5 0 0.5];         % Purple
    colorMap('No_Change_None') = [0.4 0.4 0.4];     % Darker gray for better visibility
    
    % Get time vector from first valid unit
    timeVector = getTimeVector(cellDataStruct);
    
    % Process each group separately
    groupNames = fieldnames(cellDataStruct);
    allFigures = [];
    
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        
        % Count valid units in this group
        recordings = fieldnames(cellDataStruct.(groupName));
        validUnits = [];
        
        % Collect all valid units for this group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                if isValidUnit(unitData)
                    validUnits(end+1).data = unitData;
                    validUnits(end).unit = unitID;
                end
            end
        end
        
        if isempty(validUnits)
            warning('No valid units found for group: %s', groupName);
            continue;
        end
        
        % Calculate grid dimensions for this group
        numUnits = length(validUnits);
        gridCols = ceil(sqrt(numUnits));
        gridRows = ceil(numUnits/gridCols);
        
        % Create figure for this group
        fig = figure('Position', [50 50 1500 1000]);
        allFigures = [allFigures, fig];
        sgtitle(sprintf('Group: %s', groupName), 'FontSize', 12);
        
        % Plot each unit
        for i = 1:numUnits
            subplot(gridRows, gridCols, i);
            hold on;
            
            unitData = validUnits(i).data;
            unitID = validUnits(i).unit;
            
            % Get color based on response type and subtype
            responseType = strrep(unitData.responseType, ' ', '_');
            subtype = unitData.responseMetrics.subtype;
            colorKey = sprintf('%s_%s', responseType, subtype);
            
            if ~colorMap.isKey(colorKey)
                lineColor = [0.7 0.7 0.7]; % Default gray for unknown combinations
            else
                lineColor = colorMap(colorKey);
            end
            
            % Plot z-score
            plot(timeVector, unitData.psthZScore, 'Color', lineColor, 'LineWidth', 1);
            
            % Add zero line
            yline(0, '-k', 'LineWidth', 0.5);
            
            % Customize subplot with just the unit ID
            title(unitID, 'FontSize', 8, 'Interpreter', 'none');
            
            % Set axis limits
            xlim([0 5400]);
            ylim([-1 6]);
            
            % Add labels
            xlabel('Time (s)', 'FontSize', 8);
            ylabel('Z-Score', 'FontSize', 8);
            
            % Customize grid and appearance
            grid on;
            set(gca, 'FontSize', 8);
            set(gca, 'Box', 'on');
            
            hold off;
        end
    end
    
    % Create legend figure with better formatting
    legendFig = figure('Position', [1600 500 250 300]);
    hold on;
    
    % Define order of legend entries
    responseTypes = {
        'Increased_Strong', 'Increased_Moderate', 'Increased_Variable', ...
        'Decreased_Strong', 'Decreased_Moderate', 'Decreased_Variable', ...
        'Changed_Weak', 'No_Change_None'
    };
    
    % Create legend figure with better formatting
    legendFig = figure('Position', [1600 500 300 400]);
    ax = axes('Position', [0.1 0.1 0.8 0.8]);
    hold(ax, 'on');
    
    % Define order and labels for legend entries
    responseTypes = {
        'Increased_Strong', 'Increased_Moderate', 'Increased_Variable', ...
        'Decreased_Strong', 'Decreased_Moderate', 'Decreased_Variable', ...
        'Changed_Weak', 'No_Change_None'
    };
    
    legendLabels = {
        'Enhanced (Strong)', 'Enhanced (Moderate)', 'Enhanced (Variable)', ...
        'Diminished (Strong)', 'Diminished (Moderate)', 'Diminished (Variable)', ...
        'Changed (Weak)', 'No Change'
    };
    
    % Create invisible scatter points for legend
    h = zeros(length(responseTypes), 1);
    for i = 1:length(responseTypes)
        h(i) = plot(NaN, NaN, '-', 'Color', colorMap(responseTypes{i}), ...
            'LineWidth', 2.5, 'DisplayName', legendLabels{i});
    end
    
    % Create legend
    leg = legend(h, legendLabels, ...
        'Location', 'northoutside', ...
        'Orientation', 'vertical', ...
        'FontSize', 10, ...
        'Box', 'off');
    
    % Adjust figure and legend appearance
    title(ax, 'Response Types', 'FontSize', 12, 'FontWeight', 'bold');
    axis(ax, 'off');
    set(legendFig, 'Color', 'white');
    
    % Adjust legend position
    leg.Position(1:2) = [0.1 0.1];
    
    hold(ax, 'off');


    % Save figures
    try
        % Create save directory
        saveDir = fullfile(paths.figureFolder, '0. expFigures');
        if ~isfolder(saveDir)
            mkdir(saveDir);
        end

        timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));

        % Save group figures
        for f = 1:length(allFigures)-1
            fig = allFigures(f);
            figure(fig);
            groupName = get(get(fig, 'CurrentAxes'), 'Title');
            if isempty(groupName)
                groupName = sprintf('group%d', f);
            end

            savefig(fig, fullfile(saveDir, sprintf('gridPSTHZScores_%s_%s.fig', ...
                strrep(groupName.String, ' ', ''), timeStamp)));
            print(fig, fullfile(saveDir, sprintf('gridPSTHZScores_%s_%s.tif', ...
                strrep(groupName.String, ' ', ''), timeStamp)), '-dtiff', '-r300');
        end

        % Save legend
        fig = allFigures(end);
        savefig(fig, fullfile(saveDir, sprintf('gridPSTHZScores_legend_%s.fig', timeStamp)));
        print(fig, fullfile(saveDir, sprintf('gridPSTHZScores_legend_%s.tif', timeStamp)), '-dtiff', '-r300');

        fprintf('Figures saved successfully to: %s\n', saveDir);

        close all;
    catch ME
        warning('Save:Error', 'Error saving figures: %s\n%s', ME.message, ME.stack(1).name);
    end
end



function isValid = isValidUnit(unitData)
    % Validation helper function
    isValid = isfield(unitData, 'psthZScore') && ...
              isfield(unitData, 'responseType') && ...
              isfield(unitData, 'binEdges') && ...
              isfield(unitData, 'binWidth');
end

function timeVector = getTimeVector(cellDataStruct)
    % Get time vector from first valid unit
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        recordings = fieldnames(cellDataStruct.(groupNames{g}));
        for r = 1:length(recordings)
            units = fieldnames(cellDataStruct.(groupNames{g}).(recordings{r}));
            for u = 1:length(units)
                unitData = cellDataStruct.(groupNames{g}).(recordings{r}).(units{u});
                if isValidUnit(unitData)
                    timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
                    return;
                end
            end
        end
    end
    error('No valid units found to extract time vector');
end
