function mainPlotFunction(cellDataStruct, figureFolder)
   
% Debugging: Load env variables
load('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables/cellDataStructPath.mat');
load('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables/dataFilePath.mat');
load('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables/dataFolder.mat');
load('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables/figureFolder.mat');
load('/home/silva7a-local/Documents/MATLAB/Data/eb_recordings/SpikeStuff/cellDataStruct.mat');

% Main function to create combined figure with subplots

    figure;
    t = tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact'); % Adjust as needed

    % Panel 1 - All Units with Grand Average PSTH
    % ax1 = subplot(1, 3, 1);
    % subPlotAllPSTHsRawWithMean(cellDataStruct, 1860, ax1);
    % 
    % Panel 2 - All Units (smoothed) with Recording Average 
    % ax2 = subplot(1, 3, 2);
    % subPlotAveragePSTHWithResponse(cellDataStruct, ax2);

    % Panel 3 - Experimental vs Control
    ax3 = subplot(1,3,3);
    subPlotExperimentalvsControl(cellDataStruct, ax3);

    % Additional formatting or combined annotations can go here
    title(t, 'Combined Figure with Subplots');
end


