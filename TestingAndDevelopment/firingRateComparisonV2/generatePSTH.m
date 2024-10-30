%Generate PSTH for the whole recording
function [fullPSTH, binEdges] = generatePSTH(cellDataStruct)
    % Generate PSTH for the entire recording
    
    % Specify unit for analysis
    unitData = cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314; 
    
    % Convert spike times from samples to seconds
    spikeTimes = unitData.SpikeTimesall / unitData.SpikeTimesall; % Converts spike times to s
    
    % Set binning based on recording length
    recordingLength = unitData.RecordingDuration; % Recording duration in seconds
    binWidth = unitData.binWidth;  % bin width in seconds
    
     % Calculate bin edges using the helper function
    binEdges = edgeCalculator(0, binWidth, recordingLength);  % Generate bin edges

    % if data array is given
    if max(spikeTimes)>0
        if length(spikeTimes)-(edge(end)-1) < bin % if length of data is less than 1 bin more than final starting bin
            lastbin = find(length(spikeTimes)-(edge-1) >= bin, 1, 'last' );
        else
            lastbin = length(edge);
        end
    end

    %Split Spike Data into Bins
    splitdata = zeros(floor(bin),floor(lastbin)); % prealocate 
    start_edge = edges(1:lastbin);
    end_edge = start_edge+bin-1; % add bin amount after subtracting first point
    for i = 1:lastbin
        splitdata(:,i) = data(floor(start_edge(i)):floor(end_edge(i))); % extract data
    end

    % Generate PSTH using split data
    %fullPSTH = 

    % Save PSTH to cellData struct
    cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314.psthRaw = fullPSTH;
    cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314.splitData = splitData;

end

%% Helper Functions
    % Edge calculator generates leading edges for binning
    function edges = edgeCalculator(start, binWidth, stop)
        edges = start:binWidth:stop - 1;  % Generate leading edges
    end
    