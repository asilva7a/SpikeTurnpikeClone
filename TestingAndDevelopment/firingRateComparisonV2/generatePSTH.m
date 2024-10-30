%Generate PSTH for the whole recording
function [fullPSTH, binEdges] = generatePSTH(cellDataStruct)
    % Generate PSTH for the entire recording
    
    % Specify unit for analysis
    unitData = cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314; 
    
    % Convert spike times from samples to seconds
    spikeTimes = unitData.SpikeTimesall / unitData.SpikeTimesall; % Converts spike times to s
    
    % Set binning based on recording length
    recordingLength = unitData.RecordingDuration; % Recording duration in seconds
    binWidth = unitData.binWidth;  % Flexible for full recording
    
    % Calculate bin edges using the helper function
    binEdges = edgeCalculator(0, binWidth, recordingLength);  % Generate bin edges
    
    % Compute full PSTH
    if isempty(spikeTimes) % Handling condition for empty data to prevent errors
        fullPSTH = zeros(1, length(binEdges) - 1);
    else
        fullPSTH = histcounts(spikeTimes, binEdges)/ binWidth;
    end

    % Split spike data into bins (aligning with bin edges)
    splitData = splitSpikeData(spikeTimes, binEdges);

    % Save PSTH to cellData struct
    cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314.psthRaw = fullPSTH;
    
    % Debugging: Display the PSTH length
    fprintf('Generated PSTH with %d bins for unit %s\n', length(fullPSTH), unitID);

end

%% Helper Functions
    % Edge calculator generates leading edges for binning
    function edges = edgeCalculator(start, binWidth, stop)
        edges = start:binWidth:stop - 1;  % Generate leading edges
    end

    % Split spike data into bins
    function splitData = splitSpikeData(spikeTimes, binEdges)
        % Split spikeTimes according to binEdges
        numBins = length(binEdges)-1; % Determine number of bins
        splitData = cell(1, numBins); % Preallocate array to increase efficiency

        % Loop through each bin and pull spike times
        for i = 1:numBins
            % Generate range of binEdges to look for spikes
            binStart = binEdges(i);
            binEnd = binEdges(i + 1);

            % Extract spikes w/in this bin
            splitData{i} = spikeTimes(spikeTimes >= binStart & spikeTimes < binEnd);
        end
     % Debugging: Display spikes in each bin
     for i = 1:numBins
         fprintf('Bin %d: %d spikes\n', i, length(splitData{i}));
     end
    end