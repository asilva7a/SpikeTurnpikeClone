function stats = calculateResponseStats(preRate, postRate, binWidth)
    % Calculate comprehensive statistics
    stats = struct();
    
    % Basic statistics
    stats.mean_pre = mean(preRate, 'omitnan');
    stats.mean_post = mean(postRate, 'omitnan');
    stats.std_pre = std(preRate, 'omitnan');
    stats.std_post = std(postRate, 'omitnan');
    
    % Effect size (Cohen's d)
    pooled_std = sqrt((var(preRate, 'omitnan') + var(postRate, 'omitnan'))/2);
    stats.cohens_d = (stats.mean_post - stats.mean_pre) / pooled_std;
    
    % Wilcoxon signed rank test with Bonferroni correction
    n_comparisons = length(preRate);
    alpha_corrected = 0.01 / n_comparisons;
    [stats.p_value, stats.h_wilcox] = signrank(preRate, postRate, 'alpha', alpha_corrected);
    
    % FDR control using Benjamini-Hochberg
    [stats.p_value_fdr, stats.significant_fdr] = benjaminiHochberg(stats.p_value, 0.05);
    
    % Bootstrap confidence intervals
    nBootstraps = 1000;
    bootstat_pre = bootstrp(nBootstraps, @mean, preRate);
    bootstat_post = bootstrp(nBootstraps, @mean, postRate);
    stats.ci_pre = prctile(bootstat_pre, [2.5 97.5]);
    stats.ci_post = prctile(bootstat_post, [2.5 97.5]);
    
    % Percent change
    stats.percent_change = ((stats.mean_post - stats.mean_pre) / stats.mean_pre) * 100;
    
    % Signal-to-Noise Ratio
    stats.snr = abs(stats.mean_post - stats.mean_pre) / ...
        sqrt(stats.std_pre^2 + stats.std_post^2);
    
    % Reliability score (combines effect size and significance)
    stats.reliability = abs(stats.cohens_d) * (1 - stats.p_value);
    
    % Additional metrics
    stats.spike_count_pre = sum(preRate) * binWidth;
    stats.spike_count_post = sum(postRate) * binWidth;
    stats.variance_pre = var(preRate, 'omitnan');
    stats.variance_post = var(postRate, 'omitnan');
    stats.kruskal_p = kruskalwallis([preRate(:); postRate(:)], ...
        [ones(size(preRate(:))); 2*ones(size(postRate(:)))], 'off');
end

function [p_fdr, significant] = benjaminiHochberg(p_values, q)
    % Benjamini-Hochberg FDR control
    [sorted_p, idx] = sort(p_values);
    n = length(p_values);
    k = (1:n)' * q / n;
    significant = zeros(size(p_values));
    cutoff = find(sorted_p <= k, 1, 'last');
    
    if ~isempty(cutoff)
        significant(idx(1:cutoff)) = 1;
    end
    
    % Calculate FDR-adjusted p-values
    p_fdr = min(1, sorted_p .* (n ./ (1:n)'));
    p_fdr = cummin(p_fdr(end:-1:1));  % Enforce monotonicity
    p_fdr(idx) = p_fdr;  % Restore original order
end

