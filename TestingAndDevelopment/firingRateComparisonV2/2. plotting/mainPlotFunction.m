function mainPlotFunction(cellDataStruct, figureFolder)
    % mainPlotFunction: Generates a combined figure with three subplots, each showing 
    % different aspects of neuronal population activity derived from a structured dataset. 
    % The figure is saved as a .fig file in a specified folder.
    %
    % Inputs:
    %   - cellDataStruct: A structure containing neural data, organized by groups, recordings, and units. 
    %                     This structure includes raw, smoothed, and averaged peristimulus time histograms (PSTHs).
    %   - figureFolder: Directory where the generated figure will be saved.

    % Load testing variables for debugging purposes
    % The following files load pre-set variables required for the test environment.
    % These variables can be omitted or adapted for production or deployment.
    %  Load the data
    files = {'cellDataStruct.mat', 'cellDataStructPath.mat', 'dataFilePath.mat', ...
             'dataFolder.mat', 'figureFolder.mat'};
    for i = 1:length(files)
        load(fullfile('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables', files{i}));
    end

    % Initialize figure and define tiled layout structure
    % The figure is divided into three panels horizontally arranged to display distinct data views.
    fig = figure;  % Store the figure handle for later saving
    t = tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

    % Panel 1 - Grand Average PSTH Across All Units
    % Creates a subplot displaying raw PSTHs for each unit alongside the grand average PSTH.
    ax1 = nexttile(t, 1);  % Define the first tile for the first panel
    subPlotAllPSTHsRawWithMean(cellDataStruct, 1860, ax1);  % Call helper function to plot in the specified axis
     
    % Panel 2 - Smoothed PSTH with Recording Average 
    % The second subplot displays smoothed PSTHs for individual units overlaid with a recording-level average.
    ax2 = nexttile(t, 2);  % Define the second tile for the second panel
    subPlotAveragePSTHWithResponse(cellDataStruct, ax2);

    % Panel 3 - Comparison of Experimental vs Control Groups
    % The third subplot contrasts the average PSTH for experimental and control groups with SEM shading.
    ax3 = nexttile(t, 3);  % Define the third tile for the third panel
    subPlotExperimentalvsControl(cellDataStruct, ax3);

    % Title Annotation for Combined Figure
    % Provides a descriptive title for the entire tiled layout.
    t.Title.String = 'Combined Figure with Subplots';
    t.Title.FontSize = 14;  % Set font size for enhanced readability
    t.Title.FontWeight = 'bold';  % Make the title bold to stand out

    % Set tile spacing to 'compact' for a denser layout
    % This adjusts the spacing between the subplots to make efficient use of figure space.
    t.TileSpacing = 'compact';
    t.Padding = 'compact';

    % Directory Verification and Creation
    % Ensure that the designated figure folder exists; if not, create it.
    % This is essential for file I/O operations to prevent errors in file saving.
    if ~isfolder(figureFolder)
        mkdir(figureFolder);  % Create directory if it does not exist
        fprintf('Created figure folder: %s\n', figureFolder);  % Log folder creation
    end

    % Save Figure with Timestamp
    % The figure is saved as a MATLAB .fig file, with the current timestamp appended to the filename for uniqueness.
    % datetime is used to generate a formatted timestamp.
    timestamp = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm');  % Generate timestamp in yyyy-MM-dd_HH-mm format
    fileName = sprintf('CombinedFigure_%s.fig', char(timestamp));  % Create filename with timestamp
    savefig(fig, fullfile(figureFolder, fileName));  % Save figure in .fig format in specified folder
    fprintf('Figure saved to: %s\n', fullfile(figureFolder, fileName));  % Log successful save operation
end



