function mainPlotFunction(cellDataStruct, figureFolder)
    % Debugging: Load env variables (for testing purposes)
    load('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables/cellDataStructPath.mat');
    load('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables/dataFilePath.mat');
    load('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables/dataFolder.mat');
    load('/home/silva7a-local/Documents/MATLAB/Data/eb_recordings/SpikeStuff/cellDataStruct.mat');

    % Main function to create combined figure with subplots

    % Create figure and tiled layout
    figure;
    t = tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

    % Panel 1 - All Units with Grand Average PSTH
    ax1 = nexttile(t, 1);
    subPlotAllPSTHsRawWithMean(cellDataStruct, 1860, ax1);
     
    % Panel 2 - All Units (smoothed) with Recording Average 
    ax2 = nexttile(t, 2);
    subPlotAveragePSTHWithResponse(cellDataStruct, ax2);

    % Panel 3 - Experimental vs Control
    ax3 = nexttile(t, 3);
    subPlotExperimentalvsControl(cellDataStruct, ax3);

    % Add a title for the entire tiled layout
    t.Title.String = 'Combined Figure with Subplots';
    t.Title.FontSize = 14; % Optional: adjust font size
    t.Title.FontWeight = 'bold'; % Optional: make the title bold

    % Optional: Adjust layout to fit the title better
    t.TileSpacing = 'compact';
    t.Padding = 'compact';
end



