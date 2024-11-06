% Main Script to Create Figure with Subplots and Update Specific Subplots

% Load or prepare necessary data (example data used here)
cellDataStruct = loadData();  % Replace with actual data-loading function
figureFolder = 'path_to_save_figure';  % Specify your figure save folder if needed

% Step 1: Create a new figure with a tiled layout for subplots
fig = figure;
t = tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

% Step 2: Plot each subplot independently and store axis handles for later updates
% Plot 1 - First Subplot (e.g., All Units with Grand Average PSTH)
ax1 = nexttile(t);  % First tile
subPlotAllPSTHsRawWithMean(cellDataStruct, 1860, ax1);  % Call the function to plot

% Plot 2 - Second Subplot
ax2 = nexttile(t);  % Second tile
plotSecondSubplot(cellDataStruct, ax2);  % Call the function to plot

% Plot 3 - Third Subplot
ax3 = nexttile(t);  % Third tile
plotThirdSubplot(cellDataStruct, ax3);  % Call the function to plot

% Set a common title for the entire layout
title(t, 'Combined Figure with Subplots');

% =========================================================================
% Instructions for Updating Specific Subplots
% =========================================================================
% Now that we have axis handles (ax1, ax2, ax3), we can selectively update 
% any specific subplot without replotting the others. Use the commands below 
% in the MATLAB command window or add them to this script as needed.

% Example: Update Only the Second Subplot
% ---------------------------------------
% Clear the second subplot (ax2) and replot it
% Run this command whenever you need to update only the second subplot:
% 
%   cla(ax2);  % Clear contents of ax2 without affecting ax1 or ax3
%   plotSecondSubplot(cellDataStruct, ax2);  % Replot with updated data
% 
% You can also provide new data if needed:
%   newCellDataStruct = loadNewData();  % Load new data for plotting
%   plotSecondSubplot(newCellDataStruct, ax2);  % Replot ax2 with new data

% Example: Update Multiple Subplots Independently
% -----------------------------------------------
% To update multiple subplots independently, repeat the steps for each one:
%
%   % Clear and update the first subplot
%   cla(ax1);
%   subPlotAllPSTHsRawWithMean(cellDataStruct, 1860, ax1);
%
%   % Clear and update the third subplot with different data
%   newCellDataStruct = loadNewData();
%   cla(ax3);
%   plotThirdSubplot(newCellDataStruct, ax3);

% =========================================================================
% End of Script
% =========================================================================

% Notes:
% - This script demonstrates how to set up subplots with `tiledlayout` and 
%   selectively update them using stored axis handles (ax1, ax2, ax3).
% - Replace the placeholder data-loading and plotting functions (`loadData`, 
%   `subPlotAllPSTHsRawWithMean`, `plotSecondSubplot`, `plotThirdSubplot`) 
%   with your actual data and plotting functions as needed.
% - You can save the figure to the specified `figureFolder` if needed.
