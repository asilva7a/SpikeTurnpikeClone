function [responseType, responseMetrics] = classifyResponse(stats, psth, treatmentTime, binWidth)
    % Initialize response metrics
    responseMetrics = struct();
    responseMetrics.stats = stats;
    
    % Initialize response classification
    responseType = struct('type', '', 'subtype', '');
    
    % Classify response based on multiple criteria
    if stats.p_value < 0.01  % Statistically significant change
        if stats.reliability > 0.7  % High reliability
            if stats.percent_change > 20 && stats.cohens_d > 0.8
                responseType.type = 'Increased';
                responseType.subtype = 'Strong';
            elseif stats.percent_change < -20 && stats.cohens_d < -0.8
                responseType.type = 'Decreased';
                responseType.subtype = 'Strong';
            elseif stats.cohens_d > 0.5
                responseType.type = 'Increased';
                responseType.subtype = 'Moderate';
            elseif stats.cohens_d < -0.5
                responseType.type = 'Decreased';
                responseType.subtype = 'Moderate';
            else
                responseType.type = 'Changed';
                responseType.subtype = 'Weak';
            end
        else  % Lower reliability
            if stats.mean_post > stats.mean_pre
                responseType.type = 'Increased';
                responseType.subtype = 'Variable';
            else
                responseType.type = 'Decreased';
                responseType.subtype = 'Variable';
            end
        end
    else  % Not statistically significant
        responseType.type = 'No_Change';
        responseType.subtype = 'None';
    end
    
    % Add response strength metrics
    responseMetrics.strength = struct(...
        'reliability', stats.reliability, ...
        'effect_size', stats.cohens_d, ...
        'percent_change', stats.percent_change);
    
    % Analyze temporal pattern
    temporal = analyzeTemporalPattern(psth, treatmentTime, binWidth);
    responseMetrics.temporal = temporal;
end

function temporal = analyzeTemporalPattern(psth, treatmentTime, binWidth)
    % Analyze temporal response pattern
    
    % Calculate baseline statistics
    baselineIndices = 1:floor(treatmentTime/binWidth);
    baselineMean = mean(psth(baselineIndices));
    baselineStd = std(psth(baselineIndices));
    
    % Define threshold for response
    threshold = baselineMean + 2*baselineStd;
    
    % Analyze post-treatment response
    postIndices = (floor(treatmentTime/binWidth)+1):length(psth);
    postResponse = psth(postIndices);
    
    % Calculate response characteristics
    crossings = postResponse > threshold;
    sustainedResponse = mean(crossings);
    
    % Determine temporal pattern
    if sustainedResponse > 0.75
        temporal.pattern = 'Sustained';
    elseif sustainedResponse > 0.25
        temporal.pattern = 'Transient';
    else
        temporal.pattern = 'Brief';
    end
    
    % Store additional metrics
    temporal.sustainedResponse = sustainedResponse;
    temporal.threshold = threshold;
    temporal.baselineStats = struct('mean', baselineMean, 'std', baselineStd);
end
