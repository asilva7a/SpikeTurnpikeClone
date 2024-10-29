%Generate PSTH for the whole recording
function [fullPSTH, binEdges] = generatePSTH(cellDataStruct)
    % Generate PSTH for the entire recording
    
    % Specify unit for analysis
    unitData = cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314; 
    
    % Convert spike times from samples to seconds
    spikeTimes = unitData.SpikeTimesall / unitData.SamplingFrequency; 
    
    % Set binning based on recording length
    recordingLength = unitData.RecordingDuration; % Recording duration in seconds
    binEdges = 0:unitData.binWidth:recordingLength;  % 90-minute recording assumption
    
    % Compute full PSTH
    if isempty(spikeTimes)
        fullPSTH = zeros(1, length(binEdges) - 1);
    else
        fullPSTH = histcounts(spikeTimes, binEdges) / unitData.binWidth;
    end

    % Save PSTH to cellData struct
    cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314.psthRaw = fullPSTH;

end