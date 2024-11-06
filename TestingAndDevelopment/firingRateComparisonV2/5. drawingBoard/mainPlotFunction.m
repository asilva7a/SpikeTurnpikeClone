function mainPlotFunction(cellDataStruct, figureFolder)
   
% Debugging: Load env variables
% load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\figureFolder.mat');
% load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\cellDataStructPath.mat');
% load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\dataFilePath.mat');
% load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\cellDataStruct_backup_2024-11-05_14-09-54.mat');

% Main function to create combined figure with subplots

    figure;
    t = tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact'); % Adjust as needed

    % Panel 1 - All Units with Grand Average PSTH
    ax1 = subplot(1, 3, 1);
    subPlotAllPSTHsRawWithMean(cellDataStruct, 1860, ax1);
    
    % Panel 2 - All Units (smoothed) with Recording Average, 
    ax2 = subplot(1, 3, 2);
    plotAveragePSTHWithResponse(ax2, cellDataStruct, 1860);

    % 
    % ax3 = nexttile(t);
    % plot3 = plotThirdSubplot(ax3, dataStruct); % Call subplot function 3

    % Additional formatting or combined annotations can go here
    title(t, 'Combined Figure with Subplots');
end


