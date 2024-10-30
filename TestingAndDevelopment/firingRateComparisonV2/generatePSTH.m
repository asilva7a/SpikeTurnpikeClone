function [fullPSTH, binEdges, splitData] = generatePSTH(cellDataStruct)
    %% Generate PSTH for the entire recording
    %
    %   arg1
    %   arg2 
    %
    %% 

    % Extract Unit Data
    unitData = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0;

    % Extract spiketimes for whole recording and normalize to sample rate
    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;

        % Debugging: Check spikeTimes
        disp('Spike Times (in seconds):');
        disp(spikeTimes);

   % Set Binning
    recordingLength = unitData.RecordingDuration;  % Recording length in seconds
    binWidth = unitData.binWidth;  % Bin width in seconds

        % Debugging: Check the bin width and recording length
        fprintf('Bin width: %.2f s, Recording length: %.2f s\n', binWidth, recordingLength);

    % Calculate bin edges with helper function
    binEdges = edgeCalculator(0, binWidth, recordingLength);

        % Debugging: Check bin edges
        disp('Bin Edges:');
        disp(binEdges);

    % Split Data
    numBins = length(binEdges) - 1;  % Number of bins
    splitData = cell(1, numBins);  % Preallocate cell array for bin data

        % Loop through bins and extract spikes for each bin
        for i = 1:numBins
            binStart = binEdges(i);
            binEnd = binEdges(i + 1);
    
            % Extract spikes within the current bin
            splitData{i} = spikeTimes(spikeTimes >= binStart & spikeTimes < binEnd);
    
            % Debugging: Print spikes in the current bin
            fprintf('Bin %2d | Start: %6.2f s | End: %6.2f s | Spikes: %3d\n', ...
            i, binStart, binEnd, length(splitData{i}));
        end

    % Calculate PSTH
    spikeCounts = cellfun(@length, splitData);  % Spike counts per bin
    fullPSTH = spikeCounts / binWidth;  % Convert to firing rate (spikes per second)
    
    % Plot PSTH
    plotPSTH(binEdges, fullPSTH, 1860)

    % Save PTSH to struct
    cellDataStruct.Pvalb.pvalb_hctztreat_0008_rec1.cid314.psthRaw = fullPSTH;
end

%% Helper Function: Calculate Bin Edges
function edges = edgeCalculator(start, binWidth, stop)
    % Generate the leading edges for binning
    edges = start:binWidth:stop;  % Include stop value for the last bin edge
end
