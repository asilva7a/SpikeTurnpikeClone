function avg_FR = calculate_FR(spikeTimes, StartTime, endTime, binSize)
    %Calculate firing rate by dividing the period into bins and counting spikes
    intervalBounds = StartTime:binSize:endTime;
    binnedFRs = [];

    for ii = 1:length(intervalBounds)-1
        % Count spikes within the current binned
        n_spikes = length(spikeTimes(spikeTimes >= intervalBounds(ii) & spikeTimes < intervalBounds(ii+1)));
        FR_in_bin = n_spikes / binSize;
        binned_FRs(ii) = FR_in_bin;
    end

    %Return the average firing rate across bins
    if ~isempty(binned_FRs)
        avg_FR = mean(binned_FRs);
    else
        avg_FR = 0;
    end
end
