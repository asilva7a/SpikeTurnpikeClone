function plotResponsiveUnits(dataTable)
    % plotResponsiveUnits: Generates a 3-subplot figure for different response types.
    % 
    % Input:
    %    dataTable - Table containing unit data, including 'psthSmoothed' and 'responseType'.
    
    % Debugging: Load the data table
    disp('Loading data table...');
    load('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables/dataTable.mat');

    % Extract psthSmoothed data for each response type
    disp('Extracting PSTH data based on response type...');
    increasedPSTHs = dataTable.psthSmoothed(strcmp(dataTable.responseType, 'Increased'));
    decreasedPSTHs = dataTable.psthSmoothed(strcmp(dataTable.responseType, 'Decreased'));
    noResponsePSTHs = dataTable.psthSmoothed(strcmp(dataTable.responseType, 'No Response'));

    fprintf('Number of increased response units: %d\n', numel(increasedPSTHs));
    fprintf('Number of decreased response units: %d\n', numel(decreasedPSTHs));
    fprintf('Number of no response units: %d\n', numel(noResponsePSTHs));
    
    % Calculate mean and SEM for each response type
    disp('Calculating mean and SEM for each response type...');
    [meanInc, semInc] = computeMeanSEM(increasedPSTHs);
    [meanDec, semDec] = computeMeanSEM(decreasedPSTHs);
    [meanNoResp, semNoResp] = computeMeanSEM(noResponsePSTHs);

    fprintf('Mean and SEM calculated for increased, decreased, and no response types.\n');
    
    % Create a figure with 3 subplots
    figure;
    disp('Creating figure with subplots...');

    % Plot increased response units
    subplot(1, 3, 1);
    hold on;
    disp('Plotting increased response units...');
    plotAllUnits(increasedPSTHs);  % Plot individual PSTHs
    if ~isempty(meanInc)
        shadedErrorBar(1:length(meanInc), meanInc, semInc, 'lineProps', '-r');
        disp('Plotted mean and SEM for increased response.');
    else
        disp('No data for increased response.');
    end
    title('Increased Response');
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    hold off;
    
    % Plot decreased response units
    subplot(1, 3, 2);
    hold on;
    disp('Plotting decreased response units...');
    plotAllUnits(decreasedPSTHs);  % Plot individual PSTHs
    if ~isempty(meanDec)
        shadedErrorBar(1:length(meanDec), meanDec, semDec, 'lineProps', '-b');
        disp('Plotted mean and SEM for decreased response.');
    else
        disp('No data for decreased response.');
    end
    title('Decreased Response');
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    hold off;
    
    % Plot no response units
    subplot(1, 3, 3);
    hold on;
    disp('Plotting no response units...');
    plotAllUnits(noResponsePSTHs);  % Plot individual PSTHs
    if ~isempty(meanNoResp)
        shadedErrorBar(1:length(meanNoResp), meanNoResp, semNoResp, 'lineProps', '-g');
        disp('Plotted mean and SEM for no response.');
    else
        disp('No data for no response.');
    end
    title('No Response');
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    hold off;
    
    disp('Finished plotting all response types.');
end

function plotAllUnits(PSTHcellArray)
    % plotAllUnits: Helper function to plot all PSTHs in a cell array
    disp('Plotting individual PSTHs...');
    for i = 1:length(PSTHcellArray)
        plot(PSTHcellArray{i}, 'Color', [0.8 0.8 0.8]);  % Light gray for individual traces
    end
    disp('Finished plotting individual PSTHs.');
end

function [meanPSTH, semPSTH] = computeMeanSEM(PSTHcellArray)
    % computeMeanSEM: Helper function to calculate mean and SEM across PSTHs
    disp('Computing mean and SEM...');
    if isempty(PSTHcellArray)
        disp('No data available for mean and SEM calculation.');
        meanPSTH = [];
        semPSTH = [];
        return;
    end
    PSTHMatrix = cell2mat(PSTHcellArray(:)');  % Convert cell array to matrix
    meanPSTH = mean(PSTHMatrix, 1);
    semPSTH = std(PSTHMatrix, 0, 1) / sqrt(size(PSTHMatrix, 1));
    disp('Mean and SEM calculation complete.');
end
