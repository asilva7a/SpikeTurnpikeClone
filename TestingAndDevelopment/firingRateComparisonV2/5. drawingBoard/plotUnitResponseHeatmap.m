function plotUnitResponseHeatmap(cellDataStruct, paths)
    % Initialize arrays
    depths = [];
    mediolateralPositions = [];
    baselineFR = [];
    treatmentFR = [];
    
    % Extract data
    units = fieldnames(cellDataStruct);
    for i = 1:length(units)
        unitData = cellDataStruct.(units{i});
        depths(i) = unitData.Depth;
        mediolateralPositions(i) = unitData.TemplateChannelPosition(1); % Assuming this is the mediolateral position
        baselineFR(i) = unitData.frBaselineAvg;
        treatmentFR(i) = unitData.frTreatmentAvg;
    end
    
    % Calculate percent change
    percentChange = ((treatmentFR - baselineFR) ./ baselineFR) * 100;
    
    % Create 2D grid for heatmap
    [uniqueDepths, ~, depthIndices] = unique(depths);
    [uniquePositions, ~, positionIndices] = unique(mediolateralPositions);
    
    gridSize = [length(uniqueDepths), length(uniquePositions)];
    heatmapData = accumarray([depthIndices, positionIndices], percentChange, gridSize, @mean, NaN);
    
    % Plot heatmap
    figure('Position', [100, 100, 800, 600]);
    
    % Subplot 1: Baseline Spike Frequency
    subplot(1, 2, 1);
    baselineHeatmap = accumarray([depthIndices, positionIndices], baselineFR, gridSize, @mean, NaN);
    imagesc(uniquePositions, uniqueDepths, baselineHeatmap);
    colormap(gca, hot);
    colorbar;
    title('Baseline Spike Frequency');
    xlabel('Mediolateral Axis (μm)');
    ylabel('Depth (μm)');
    set(gca, 'YDir', 'reverse');
    
    % Subplot 2: Change in spike frequency
    subplot(1, 2, 2);
    imagesc(uniquePositions, uniqueDepths, heatmapData);
    colormap(gca, redblue(256));
    colorbar;
    title('Change in spike frequency during treatment (%)');
    xlabel('Mediolateral Axis (μm)');
    ylabel('Depth (μm)');
    set(gca, 'YDir', 'reverse');
    
    % Adjust colorbar limits to match example (-100% to 100%)
    caxis([-100, 100]);
    
    % Save figure
    saveas(gcf, fullfile(paths.figureFolder, '0. expFigures', 'UnitResponseHeatmap.fig'));
    saveas(gcf, fullfile(paths.figureFolder, '0. expFigures', 'UnitResponseHeatmap.png'));
end

function c = redblue(m)
    % Custom colormap function (red-white-blue)
    if nargin < 1, m = 64; end
    if mod(m,2) == 0
        m = m+1;
    end
    m2 = floor(m/2);
    
    r = [linspace(0,1,m2)'; ones(m2,1)];
    g = [linspace(0,1,m2)'; linspace(1,0,m2)'];
    b = [ones(m2,1); linspace(1,0,m2)'];
    
    c = [r g b];
end
