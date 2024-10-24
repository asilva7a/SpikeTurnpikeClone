function avg_FR = calculateFiringRate_fun(spikeTimes, StartTime, endTime, binSize)
    % Calculate firing rate by dividing the period into bins and counting spikes
    intervalBounds = StartTime:binSize:endTime;
    numBins = length(intervalBounds) - 1;
    binned_FRs = zeros(1, numBins);

    for ii = 1:numBins
        % Count spikes within the current bin
        n_spikes = sum(spikeTimes >= intervalBounds(ii) & spikeTimes < intervalBounds(ii+1));
        binned_FRs(ii) = n_spikes / binSize;
    end

    % Return the average firing rate across bins
    if numBins > 0
        avg_FR = mean(binned_FRs);
    else
        avg_FR = 0;
    end
end
