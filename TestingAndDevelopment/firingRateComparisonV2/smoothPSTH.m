function [smoothedPSTH, cellDataStruct]= smoothPSTH(cellDataStruct)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    % Pull relevant data from struct
    load("TestData\cellDataStruct.mat","cellDataStruct");
    psthRough = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.psthRaw;

    % Define Boxcar filter
    boxcar = [1 1 1 1];
    boxcar = boxcar/sum(boxcar);

    % Apply smoothing to rough PSTH
    smoothedPSTH = conv(psthRough, boxcar, 'same');
    
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


% To Do
%   Need
%       1. working function
%   Want
%       1. Input for additional arguments for addtional smoothing windows
%   