function [smoothedPSTH, cellDataStruct]= smoothPSTH(cellDataStruct, windowSize)
% smoothPSTH: Smooths the raw PSTH using a boxcar filter of given size.
    % 
    % Inputs:
    %   - cellDataStruct: Input structure containing raw PSTH data
    %   - windowSize: Size of the smoothing window (default is 5)
    %
    % Outputs:
    %   - smoothedPSTH: The smoothed PSTH
    %   - cellDataStruct: Updated structure with smoothed PSTH


%% Load Data
    % Pull relevant data from struct
    load("TestData\cellDataStruct.mat","cellDataStruct");
    psthRough = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.psthRaw;

%% Apply smoothing
    % Respond to user input
    if nargin < 2
        windowSize = 5;
    end

    % Define boxcar smoothing
    boxcar = ones(1, windowSize)/windowSize;

    % Apply smoothing to rough PSTH
    smoothedPSTH = conv(psthRough, boxcar, 'same');

    %% Save smoothed PSTH
    % Save smoothed PSTH to struct
    try
        cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.psthSmoothed = smoothedPSTH;
        disp('Smoothed PSTH successfully saved to struct.');
    catch ME
        warning('%s: %s', ME.identifier, ME.message);  % Include format specifier
    end
    
        % Debugging: Check data saved to struct
        disp('Updated Cell Data Struct:');
        disp(cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0);

    % Save Struct to file
    saveDir = 'C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData';
    savePath = fullfile(saveDir, 'cellDataStruct.mat');

    if isfile(savePath)
        disp('Overwriting existing file.');
        delete(savePath);  % Remove old file
    else
        disp('Saving new file.');
    end

    try
        save(savePath, 'cellDataStruct', '-v7');
        disp('Struct saved successfully.');
    catch ME
        disp('Error saving the file:');
        disp(ME.message);
    end    
end
