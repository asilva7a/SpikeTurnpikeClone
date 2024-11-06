function plotResponsiveUnits(dataTable)
    % plotResponsiveUnits: Generates a 3-subplot figure for different response types.
    % 
    % Input:
    %    dataTable - Table containing unit data, including 'psthSmoothed' and 'responseType'.
    

    % Debugging: Load the data table
    load('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables/dataTable.mat');

    % Extract psthSmoothed data for each response type
    % Assume 'responseType' categorizes units as 'increased', 'decreased', or 'no response'
    increasedPSTHs = dataTable.psthSmoothed(strcmp(dataTable.responseType, 'Increased'));
    decreasedPSTHs = dataTable.psthSmoothed(strcmp(dataTable.responseType, 'Decreased'));
    noResponsePSTHs = dataTable.psthSmoothed(strcmp(dataTable.responseType, 'No Response'));
    
    % Calculate mean and SEM for each response type
    % Helper function to compute mean and SEM for a cell array of PSTHs
    [meanInc, semInc] = computeMeanSEM(increasedPSTHs);
    [meanDec, semDec] = computeMeanSEM(decreasedPSTHs);
    [meanNoResp, semNoResp] = computeMeanSEM(noResponsePSTHs);

    % Create a figure with 3 subplots
    figure;
    
    % Plot increased response units
    subplot(1, 3, 1);
    hold on;
    plotAllUnits(increasedPSTHs);  % Plot individual PSTHs
    shadedErrorBar(1:length(meanInc), meanInc, semInc, 'lineProps', '-r');
    title('Increased Response');
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    hold off;

    % Plot decreased response units
    subplot(1, 3, 2);
    hold on;
    plotAllUnits(decreasedPSTHs);  % Plot individual PSTHs
    shadedErrorBar(1:length(meanDec), meanDec, semDec, 'lineProps', '-b');
    title('Decreased Response');
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    hold off;

    % Plot no response units
    subplot(1, 3, 3);
    hold on;
    plotAllUnits(noResponsePSTHs);  % Plot individual PSTHs
    shadedErrorBar(1:length(meanNoResp), meanNoResp, semNoResp, 'lineProps', '-g');
    title('No Response');
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    hold off;

end

function plotAllUnits(PSTHcellArray)
    % plotAllUnits: Helper function to plot all PSTHs in a cell array
    for i = 1:length(PSTHcellArray)
        plot(PSTHcellArray{i}, 'Color', [0.8 0.8 0.8]);  % Light gray for individual traces
    end
end

function [meanPSTH, semPSTH] = computeMeanSEM(PSTHcellArray)
    % computeMeanSEM: Helper function to calculate mean and SEM across PSTHs
    % Assumes each PSTH in PSTHcellArray has the same length
    if isempty(PSTHcellArray)
        meanPSTH = [];
        semPSTH = [];
        return;
    end
    PSTHMatrix = cell2mat(PSTHcellArray(:)');  % Convert cell array to matrix
    meanPSTH = mean(PSTHMatrix, 1);
    semPSTH = std(PSTHMatrix, 0, 1) / sqrt(size(PSTHMatrix, 1));
end
