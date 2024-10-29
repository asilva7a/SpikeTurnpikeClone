%Generate PSTH for the whole recording
function [fullPSTH, binEdges] = generatePSTH(cellDataStruct)
    % Generate PSTH for the entire recording
    
    % Specify unit for analysis
    unitData = cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314; 
    
    % Convert spike times from samples to seconds
    spikeTimes = unitData.SpikeTimesall / unitData.SpikeTimesall; % Converts spike times to s
    
    % Set binning based on recording length
    recordingLength = unitData.RecordingDuration; % Recording duration in seconds
    binWidth = 0:unitData.binWidth:recordingLength-1;  % Flexible for full recording
    
    % Calculate bin edges using the helper function
    binEdges = calculateEdges(0, binWidth, recordingLength);  % Generate bin edges
    
    % Compute full PSTH
    %if isempty(spikeTimes)
        %fullPSTH = zeros(1, length(binEdges) - 1);
    %else
        fullPSTH = histcounts(spikeTimes, binEdges); %/ unitData.binWidth;
    %end

    % Save PSTH to cellData struct
    cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314.psthRaw = fullPSTH;
    
    % Debugging: Display the PSTH length
    fprintf('Generated PSTH with %d bins for unit %s\n', length(fullPSTH), unitID);

end