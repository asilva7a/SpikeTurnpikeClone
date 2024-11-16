function [responseType, metrics] = classifyResponse(preRate, postRate, params)
    % Calculate multiple metrics for more robust classification
    
    % 1. Statistical significance
    [pValue, ~] = signrank(preRate, postRate);
    
    % 2. Effect size (Cohen's d)
    cohensD = (mean(postRate) - mean(preRate)) / ...
              sqrt((var(preRate) + var(postRate))/2);
    
    % 3. Percent change
    percentChange = ((mean(postRate) - mean(preRate)) / mean(preRate)) * 100;
    
    % 4. Signal-to-noise ratio
    preNoise = std(preRate);
    postNoise = std(postRate);
    snrChange = abs(mean(postRate) - mean(preRate)) / sqrt(preNoise^2 + postNoise^2);
    
    % Classify response using multiple criteria
    if pValue < 0.05
        if cohensD > 0.8 && percentChange > 20
            responseType = 'Strong Increase';
        elseif cohensD < -0.8 && percentChange < -20
            responseType = 'Strong Decrease';
        elseif cohensD > 0.5
            responseType = 'Moderate Increase';
        elseif cohensD < -0.5
            responseType = 'Moderate Decrease';
        else
            responseType = 'Weak Change';
        end
    else
        responseType = 'No Change';
    end
    
    % Store metrics
    metrics.pValue = pValue;
    metrics.cohensD = cohensD;
    metrics.percentChange = percentChange;
    metrics.snr = snrChange;
end
