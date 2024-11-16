function calculatePvalbBaselineStats(cellDataStruct)
    % Initialize storage for each response type
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    baselineWindow = [300 1860]; % 5-31 minutes
    
    % Initialize results structure
    results = struct();
    for rt = 1:length(responseTypes)
        results.(responseTypes{rt}) = struct('baseline', [], 'n', 0);
    end
    
    % Process Pvalb units
    if ~isfield(cellDataStruct, 'Pvalb')
        disp('No Pvalb units found');
        return;
    end
    
    % Get recordings
    recordings = fieldnames(cellDataStruct.Pvalb);
    
    % Process each recording
    for r = 1:length(recordings)
        units = fieldnames(cellDataStruct.Pvalb.(recordings{r}));
        
        % Get time vector from first unit
        firstUnit = cellDataStruct.Pvalb.(recordings{r}).(units{1});
        timeVector = firstUnit.binEdges(1:end-1) + firstUnit.binWidth/2;
        baselineIdx = timeVector >= baselineWindow(1) & timeVector <= baselineWindow(2);
        
        % Process each unit
        for u = 1:length(units)
            unitData = cellDataStruct.Pvalb.(recordings{r}).(units{u});
            
            if ~isfield(unitData, 'responseType') || ~isfield(unitData, 'psthSmoothed')
                continue;
            end
            
            responseType = strrep(unitData.responseType, ' ', '');
            if ~ismember(responseType, responseTypes)
                continue;
            end
            
            % Calculate baseline mean for this unit
            baselineMean = mean(unitData.psthSmoothed(baselineIdx));
            results.(responseType).baseline = [results.(responseType).baseline; baselineMean];
            results.(responseType).n = results.(responseType).n + 1;
        end
    end
    
    % Calculate and display statistics for each response type
    disp('Pvalb Baseline Statistics (5-31 minutes):');
    disp('----------------------------------------');
    for rt = 1:length(responseTypes)
        responseType = responseTypes{rt};
        if results.(responseType).n > 0
            baselineMean = mean(results.(responseType).baseline);
            baselineSEM = std(results.(responseType).baseline) / sqrt(length(results.(responseType).baseline));
            fprintf('%s Units (n=%d):\n', responseType, results.(responseType).n);
            fprintf('Mean ± SEM: %.3f ± %.3f Hz\n\n', baselineMean, baselineSEM);
        else
            fprintf('%s Units: No units found\n\n', responseType);
        end
    end
end
