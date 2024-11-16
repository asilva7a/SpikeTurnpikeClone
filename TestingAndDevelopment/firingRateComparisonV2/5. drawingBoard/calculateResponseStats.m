function stats = calculateResponseStats(preRate, postRate, params)
    % Calculates comprehensive statistics for unit response
    %
    % Inputs:
    %   preRate - firing rate before treatment
    %   postRate - firing rate after treatment
    %   params - analysis parameters structure
    
    % Initialize stats structure
    stats = struct();
    
    % 1. Basic Statistics
    stats.mean_pre = mean(preRate, 'omitnan');
    stats.mean_post = mean(postRate, 'omitnan');
    stats.std_pre = std(preRate, 'omitnan');
    stats.std_post = std(postRate, 'omitnan');
    
    % 2. Wilcoxon Signed Rank Test
    [stats.p_value, stats.h_wilcox] = signrank(preRate, postRate, 'alpha', 0.05);
    
    % 3. Effect Size (Cohen's d)
    pooled_std = sqrt((var(preRate, 'omitnan') + var(postRate, 'omitnan'))/2);
    stats.cohens_d = (stats.mean_post - stats.mean_pre) / pooled_std;
    
    % 4. Bootstrap Confidence Intervals
    nBootstraps = 1000;
    bootstat_pre = bootstrp(nBootstraps, @mean, preRate);
    bootstat_post = bootstrp(nBootstraps, @mean, postRate);
    stats.ci_pre = prctile(bootstat_pre, [2.5 97.5]);
    stats.ci_post = prctile(bootstat_post, [2.5 97.5]);
    
    % 5. Percent Change
    stats.percent_change = ((stats.mean_post - stats.mean_pre) / stats.mean_pre) * 100;
    
    % 6. Signal-to-Noise Ratio
    stats.snr = abs(stats.mean_post - stats.mean_pre) / ...
                sqrt(stats.std_pre^2 + stats.std_post^2);
    
    % 7. Reliability Score (combines effect size and significance)
    stats.reliability = abs(stats.cohens_d) * (1 - stats.p_value);
end

