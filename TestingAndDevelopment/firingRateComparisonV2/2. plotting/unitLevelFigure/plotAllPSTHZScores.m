function plotAllPSTHZScores(cellDataStruct, treatmentTime, figureFolder)
    % Set defaults
    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 2000;
        fprintf('No treatment time specified. Using default: %d ms.\n', treatmentTime);
    end
    
    if nargin < 3 || isempty(figureFolder)
        error('Plot:NoFolder', 'Figure folder path is required');
    end
    
    % Initialize results tracking
    results = struct('total', 0, 'success', 0, 'errors', 0);
    
    % Process each group
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                results.total = results.total + 1;
                
                try
                    % Get unit data
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    
                    % Validate data
                    if ~isValidUnit(unitData)
                        warning('Plot:InvalidUnit', 'Invalid Z-score data for unit %s', unitID);
                        continue;
                    end
                    
                    % Create unit directory
                    saveDir = fullfile(figureFolder, groupName, recordingName, unitID);
                    if ~isfolder(saveDir)
                        mkdir(saveDir);
                    end
                    
                    % Create and save plot
                    if generateAndSavePlot(unitData, unitID, groupName, recordingName, treatmentTime, saveDir)
                        results.success = results.success + 1;
                    else
                        results.errors = results.errors + 1;
                    end
                    
                catch ME
                    results.errors = results.errors + 1;
                    warning('Plot:UnitError', 'Error processing unit %s: %s', unitID, ME.message);
                end
            end
        end
    end
    
    % Display summary
    displaySummary(results);
end

function isValid = isValidUnit(unitData)
    isValid = isfield(unitData, 'binEdges') && ...
              isfield(unitData, 'psthZScore') && ...
              ~isempty(unitData.binEdges) && ...
              ~isempty(unitData.psthZScore);
end

function success = generateAndSavePlot(unitData, unitID, groupName, recordingName, treatmentTime, saveDir)
    try
        % Create figure
        f = figure('Visible', 'on', 'Position', [100, 100, 800, 600]);
        
        % Plot PSTH
        bar(unitData.binEdges(1:end-1), unitData.psthZScore, 'FaceColor', 'k', 'EdgeColor', 'k');
        hold on;
        
        % Add treatment line
        xline(treatmentTime, '--r', 'LineWidth', 2);
        
        % Set axes
        xlabel('Time (s)');
        ylabel('z Score');
        title(sprintf('PSTH Z Score: %s - %s - %s', groupName, recordingName, unitID));
        
        % Set limits
        maxY = max(unitData.psthZScore(~isnan(unitData.psthZScore)));
        if ~isempty(maxY) && ~isnan(maxY) && maxY > 0
            ylim([0, maxY * 1.1]);
        else
            ylim([0, 1]);
        end
        xlim([min(unitData.binEdges), max(unitData.binEdges)]);
        
        % Style
        set(gca, 'Box', 'off', 'TickDir', 'out', 'FontSize', 10, 'LineWidth', 1.2);
        
        % Add metadata
        addMetadata(unitData, unitID);
        
        % Save figure
        timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss'));
        fileName = sprintf('RawPSTH_%s_%s.fig', unitID, timestamp);
        savefig(f, fullfile(saveDir, fileName));
        
        close(f);
        success = true;
    catch
        success = false;
    end
end

function addMetadata(unitData, unitID)
    % Generate metadata text
    cellType = unitData.CellType;
    channel = unitData.TemplateChannel;
    unitStatus = ternary(unitData.IsSingleUnit == 1, 'Single Unit', 'Not Single Unit');
    
    metaText = sprintf('Cell Type: %s\nChannel: %d\n%s\nUnit ID: %s', ...
                      cellType, channel, unitStatus, unitID);
    
    % Create draggable annotation
    ann = annotation('textbox', [0.7, 0.8, 0.25, 0.15], ... % [x, y, width, height]
                    'String', metaText, ...
                    'EdgeColor', 'k', ...         % Black border
                    'BackgroundColor', 'w', ...   % White background
                    'HorizontalAlignment', 'left', ...
                    'VerticalAlignment', 'top', ...
                    'FontSize', 8, ...
                    'FitBoxToText', 'on', ...     % Adjust box size to fit text
                    'LineWidth', 1, ...           % Border width
                    'Margin', 5, ...              % Text margin inside box
                    'Interpreter', 'none');
    
    % Make annotation draggable
    set(ann, 'ButtonDownFcn', @startDragFcn);
end

function startDragFcn(src, ~)
    % Store initial position and setup mouse callbacks
    setappdata(src, 'InitialPosition', get(src, 'Position'));
    setappdata(src, 'InitialClick', get(gcf, 'CurrentPoint'));
    
    % Set up mouse movement and release callbacks
    set(gcf, 'WindowButtonMotionFcn', {@dragFcn, src});
    set(gcf, 'WindowButtonUpFcn', {@stopDragFcn, src});
end

function dragFcn(~, ~, ann)
    % Get initial data
    initPos = getappdata(ann, 'InitialPosition');
    initClick = getappdata(ann, 'InitialClick');
    
    % Get figure handle and position
    fig = gcf();
    figPos = get(fig, 'Position');
    currentPoint = get(fig, 'CurrentPoint');
    
    % Calculate movement
    deltaX = (currentPoint(1) - initClick(1)) / figPos(3);
    deltaY = (currentPoint(2) - initClick(2)) / figPos(4);
    
    % Update position
    newPos = initPos + [deltaX deltaY 0 0];
    set(ann, 'Position', newPos);
end

function stopDragFcn(fig, ~, ann)
    % Clear mouse callbacks
    set(fig, 'WindowButtonMotionFcn', '');
    set(fig, 'WindowButtonUpFcn', '');
    
    % Store final position
    setappdata(ann, 'InitialPosition', get(ann, 'Position'));
end

function result = ternary(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end

function displaySummary(results)
    fprintf('\nProcessing Summary:\n');
    fprintf('Total Units: %d\n', results.total);
    fprintf('Successful: %d\n', results.success);
    fprintf('Failed: %d\n', results.errors);
    fprintf('Success Rate: %.1f%%\n', (results.success/results.total)*100);
end


