function [silence_score_before, silence_score_after] = calculateSilenceScore(FR_before, FR_after, binWidth, silence_threshold)
    % Calculate silence scores for pre- and post-treatment periods
    %
    % Inputs:
    % - FR_before: Firing rates for pre-treatment period
    % - FR_after: Firing rates for post-treatment period
    % - binWidth: Width of each bin in seconds
    % - silence_threshold: Threshold for considering a bin as silent
    %
    % Outputs:
    % - silence_score_before: Silence score for pre-treatment period
    % - silence_score_after: Silence score for post-treatment period

    function score = calcScore(FR)
        total_time = length(FR) * binWidth;
        silent_time = sum(FR < silence_threshold) * binWidth;
        score = silent_time / total_time;
    end

    silence_score_before = calcScore(FR_before);
    silence_score_after = calcScore(FR_after);
end
