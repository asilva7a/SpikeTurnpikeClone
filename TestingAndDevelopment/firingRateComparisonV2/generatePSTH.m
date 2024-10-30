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
    fprintf('Generated PSTH with %d bins for unit %s\n', length(fullPSTH), unitData);

end

%% Helper Functions
    % Edge calculator generates leading edges for binning
    function edges = edgeCalculator(start, binWidth, stop)
        edges = start:binWidth:stop - 1;  % Generate leading edges
    end
    
    % % Split spike data into bins (need to finish)
    % function splitData = splitSpikeData(spikeTimes, binEdges)
    %     if max(spikeTimes) > 0
    %         if length(spikeTimes)-(edge(end)-1) < bin % if length of data is less than 1 bin more than final starting bin
    %             lastbin = max(find(length(data)-(edge-1) >= bin));
    %         else
    %             lastbin = length(edge);
    %         end
    % 
    % % split the data using the bins
    %         splitdata = zeros(floor(bin),floor(lastbin)); % prealocate
    %         start_edge = edge(1:lastbin);
    %         end_edge = start_edge+bin-1; % add bin amount after subtracting first point
    %         for i = 1:lastbin
    %             splitdata(:,i) = data(floor(start_edge(i)):floor(end_edge(i))); % extract data
    %         end
    %     end

     % Debugging: Display spikes in each bin
     for i = 1:numBins
         fprintf('Bin %d: %d spikes\n', i, length(splitData{i}));
     end
    end