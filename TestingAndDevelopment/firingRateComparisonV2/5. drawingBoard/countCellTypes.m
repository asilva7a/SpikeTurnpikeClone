function [UnitPop,SpikingPop,ComplexPop] = countCellTypes(cellDataStruct, paths)
    % Initialize counters for each group
    groupNames = fieldnames(cellDataStruct);
    numGroups = length(groupNames);
    
    % Initialize data arrays
    singleUnits = zeros(numGroups, 1);
    multiUnits = zeros(numGroups, 1);
    fastSpikingUnits = zeros(numGroups, 1);
    regularSpikingUnits = zeros(numGroups, 1);
    unknownType = zeros(numGroups, 1);
    singleFS = zeros(numGroups, 1);
    singleRS = zeros(numGroups, 1);
    multiFS = zeros(numGroups, 1);
    multiRS = zeros(numGroups, 1);
    unclassified = zeros(numGroups, 1);
    
    % Process each group
    for g = 1:numGroups
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Count single vs multi units
                if isfield(unitData, 'IsSingleUnit')
                    if unitData.IsSingleUnit == 1
                        singleUnits(g) = singleUnits(g) + 1;
                    else
                        multiUnits(g) = multiUnits(g) + 1;
                    end
                end
                
                % Count firing types
                if isfield(unitData, 'CellType')
                    switch unitData.CellType
                        case 'FS'
                            fastSpikingUnits(g) = fastSpikingUnits(g) + 1;
                        case 'RS'
                            regularSpikingUnits(g) = regularSpikingUnits(g) + 1;
                        otherwise
                            unknownType(g) = unknownType(g) + 1;
                    end
                else
                    unknownType(g) = unknownType(g) + 1;
                end
                
                % Combined classification
                isSingle = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                isMulti = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 0;
                
                if isfield(unitData, 'CellType')
                    switch unitData.CellType
                        case 'FS'
                            if isSingle
                                singleFS(g) = singleFS(g) + 1;
                            elseif isMulti
                                multiFS(g) = multiFS(g) + 1;
                            end
                        case 'RS'
                            if isSingle
                                singleRS(g) = singleRS(g) + 1;
                            elseif isMulti
                                multiRS(g) = multiRS(g) + 1;
                            end
                        otherwise
                            unclassified(g) = unclassified(g) + 1;
                    end
                else
                    unclassified(g) = unclassified(g) + 1;
                end
            end
        end
    end
    
    % Create tables
    UnitPop = table(groupNames, singleUnits, multiUnits, ...
        'VariableNames', {'Group', 'SingleUnits', 'MultiUnits'});
    
    SpikingPop = table(groupNames, fastSpikingUnits, regularSpikingUnits, unknownType, ...
        'VariableNames', {'Group', 'FastSpiking', 'RegularSpiking', 'Unknown'});
    
    ComplexPop = table(groupNames, singleFS, singleRS, multiFS, multiRS, unclassified, ...
        'VariableNames', {'Group', 'SingleFS', 'SingleRS', 'MultiFS', 'MultiRS', 'Unclassified'});
    
    % Display tables with headers
    fprintf('\nUnit Classification Summary:\n');
    fprintf('-------------------------\n');
    disp(UnitPop);
    
    fprintf('\nFiring Type Summary:\n');
    fprintf('------------------\n');
    disp(SpikingPop);
    
    fprintf('\nDetailed Classification Summary:\n');
    fprintf('-----------------------------\n');
    disp(ComplexPop);
    
    % Save tables
    try
        % Create timestamp for unique filenames
        timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
        
        % Save tables to data folder
        dataDir = fullfile(paths.dataFolder, 'frTreatmentAnalysis', 'data');
        if ~exist(dataDir, 'dir')
            mkdir(dataDir);
        end
        
        % Save each table with descriptive filename
        writetable(T1, fullfile(dataDir, sprintf('UnitClassification_%s.csv', timestamp)));
        writetable(T2, fullfile(dataDir, sprintf('FiringTypeDistribution_%s.csv', timestamp)));
        writetable(T3, fullfile(dataDir, sprintf('DetailedClassification_%s.csv', timestamp)));
        
    catch ME
        warning('Save:Error', 'Error saving files: %s', ME.message);
    end

    % Create visualization figures
    visualizeData(UnitPop, SpikingPop, ComplexPop, groupNames);

end

function visualizeData(T1, T2, T3, ~)
    % Create figure with subplots
    figure('Position', [100 100 1200 800]);
    
    % Plot 1: Single vs Multi Units
    subplot(2,2,1);
    data1 = [T1.SingleUnits T1.MultiUnits];
    b1 = bar(data1, 'stacked');
    title('Unit Classification');
    xlabel('Group');
    ylabel('Count');
    legend('Single Units', 'Multi Units', 'Location', 'northoutside');
    set(gca, 'XTickLabel', T1.Group);
    
    % Plot 2: Firing Types
    subplot(2,2,2);
    data2 = [T2.FastSpiking T2.RegularSpiking T2.Unknown];
    b2 = bar(data2, 'stacked');
    title('Firing Type Distribution');
    xlabel('Group');
    ylabel('Count');
    legend('Fast Spiking', 'Regular Spiking', 'Unknown', 'Location', 'northoutside');
    set(gca, 'XTickLabel', T2.Group);
    
    % Plot 3: Detailed Classification
    subplot(2,2,3);
    data3 = [T3.SingleFS T3.SingleRS T3.MultiFS T3.MultiRS T3.Unclassified];
    b3 = bar(data3, 'stacked');
    title('Detailed Unit Classification');
    xlabel('Group');
    ylabel('Count');
    legend('Single FS', 'Single RS', 'Multi FS', 'Multi RS', 'Unclassified', ...
           'Location', 'northoutside');
    set(gca, 'XTickLabel', T3.Group);
    
    % Plot 4: Pie Charts
    subplot(2,2,4);
    for g = 1:height(T1)
        pie([T3.SingleFS(g), T3.SingleRS(g), T3.MultiFS(g), T3.MultiRS(g), T3.Unclassified(g)]);
        title(sprintf('%s Distribution', T1.Group{g}));
        legend('Single FS', 'Single RS', 'Multi FS', 'Multi RS', 'Unclassified', ...
               'Location', 'southoutside');
        break; % Only show first group's pie chart
    end
    
    % Add value labels on bars
    addValueLabels(subplot(2,2,1), data1);
    addValueLabels(subplot(2,2,2), data2);
    addValueLabels(subplot(2,2,3), data3);
    
    % Adjust layout
    sgtitle('Unit Type Distribution Analysis');
    set(gcf, 'Color', 'w')
    
    % Save Figures
    try 
        % Save figures to figure folder
        figDir = fullfile(paths.figureFolder, '0. expFigures');
        if ~exist(figDir, 'dir')
            mkdir(figDir);
        end
        
        % Save visualization figure
        savefig(gcf, fullfile(figDir, sprintf('UnitDistribution_%s.fig', timestamp)));
        print(gcf, fullfile(figDir, sprintf('UnitDistribution_%s.tif', timestamp)), '-dtiff', '-r300');
        
        fprintf('Files saved successfully:\n');
        fprintf('Data: %s\n', dataDir);
        fprintf('Figures: %s\n', figDir);
        
    catch ME
        warning('Save:Error', 'Error saving files: %s', ME.message);
    end
end

function addValueLabels(ax, data)
    axes(ax);
    for i = 1:size(data,1)
        ypos = cumsum(data(i,:));
        for j = 1:length(ypos)
            if data(i,j) > 0
                text(i, ypos(j), num2str(data(i,j)), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom');
            end
        end
    end
end
