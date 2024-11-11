function visualizeBootstrapResults(bootstats, pValue, preMean, postMean, bootCenter, responseType)
    % visualizeBootstrapResults: Generates figures to verify hierarchical bootstrap results.
    %
    % Inputs:
    %   - bootstats: 2xN array containing bootstrapped pre- and post-treatment distributions.
    %   - pValue: Bootstrap p-value.
    %   - preMean, postMean: Mean firing rates before and after treatment.
    %   - bootCenter: Array containing the mean of bootstrapped distributions.
    %   - responseType: Label indicating 'Increased', 'Decreased', or 'Unchanged'.

    figure;
    
    % 1. Bootstrap Distribution Histograms
    subplot(2, 2, 1);
    histogram(bootstats(1, :), 50, 'FaceColor', 'b', 'EdgeColor', 'k', 'DisplayName', 'Pre-treatment');
    hold on;
    histogram(bootstats(2, :), 50, 'FaceColor', 'r', 'EdgeColor', 'k', 'DisplayName', 'Post-treatment');
    xlabel('Bootstrap Means');
    ylabel('Frequency');
    title('Bootstrap Distributions');
    legend('Pre-treatment', 'Post-treatment');
    hold off;

    % 2. Difference Distribution Histogram
    subplot(2, 2, 2);
    diffDistribution = bootstats(2, :) - bootstats(1, :);
    histogram(diffDistribution, 50, 'FaceColor', 'm', 'EdgeColor', 'k');
    xlabel('Difference (Post - Pre)');
    ylabel('Frequency');
    title('Difference Distribution (Post - Pre)');

    % 3. Confidence Intervals and Mean Firing Rates
    subplot(2, 2, 3);
    bar([1, 2], [preMean, postMean], 'FaceColor', 'flat');
    hold on;
    errorbar([1, 2], bootCenter, std(bootstats, [], 2), 'k.', 'LineWidth', 1.5);
    xticks([1, 2]);
    xticklabels({'Pre-treatment', 'Post-treatment'});
    ylabel('Mean Firing Rate (spikes/s)');
    title('Mean Firing Rates with Confidence Intervals');
    text(1.5, max([preMean, postMean]) * 1.1, sprintf('p-value: %.4f\nResponse: %s', pValue, responseType), ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
    hold off;

    % 4. Ladder Plot for Visualizing Pre- and Post-treatment Changes
    subplot(2, 2, 4);
    plot([1, 2], [preMean, postMean], '-o', 'Color', [0.6, 0.6, 0.6], 'MarkerFaceColor', 'k', 'LineWidth', 1.5);
    xlim([0.8, 2.2]);
    xticks([1, 2]);
    xticklabels({'Pre-treatment', 'Post-treatment'});
    ylabel('Mean Firing Rate (spikes/s)');
    title('Ladder Plot for Firing Rate Change');
    
    % Adjust overall figure title
    sgtitle('Sanity Check: Bootstrap Analysis Results');
end
