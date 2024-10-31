function [cellDataStruct] = calculateFiringRate(unitData, dataFilePath, moment)    
    % Calculate firing rate by dividing the period into bins and counting spikes
    recordingDuration = unit



% 
%     for ii = 1:numBins
%         % Count spikes within the current bin
%         n_spikes = sum(spikeTimes >= intervalBounds(ii) & spikeTimes < intervalBounds(ii+1));
%         binned_FRs(ii) = n_spikes / binSize;
%     end
% 
%     % Return the average firing rate across bins
%     if numBins > 0
%         avg_FR = mean(binned_FRs);
%     else
%         avg_FR = 0;
%     end
% end