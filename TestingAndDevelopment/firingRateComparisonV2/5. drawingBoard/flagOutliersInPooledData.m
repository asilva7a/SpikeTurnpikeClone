function [cellDataStruct, groupIQRs] = flagOutliersInPooledData(cellDataStruct, unitFilter, plotOutliers)
    % flagOutliersInPooledData: Identifies and flags extreme outlier units based on smoothed PSTHs.
    % Uses a strict IQR-based threshold with a k-factor of 3.0 for extreme outliers.

    % Default input setup for debugging
    if nargin < 3
        plotOutliers = true;
    end
    if nargin < 2
        unitFilter = 'both';
    end
    if nargin < 1
        error('cellDataStruct not provided. Please provide a cellDataStruct.');
    end

    % Define response types and groups
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    groups = {'Emx', 'Pvalb'};

    % Initialize groupIQRs structure to store IQR and upper fence for each response type and group
    groupIQRs = struct();
    for rType = responseTypes
        groupIQRs.(rType{1}) = struct();
        for grp = groups
            groupIQRs.(rType{1}).(grp{1}) = struct('IQR', [], 'Median', [], 'UpperFence', []);
        end
    end

    % Loop through each response type and calculate IQR and extreme outliers for Emx and Pvalb groups
    for rType = responseTypes
        emxRates = [];
        pvalbRates = [];

        % Collect maximum firing rates for each group within the response type
        for g = 1:length(unitInfoGroup.(rType{1}))
            unitInfo = unitInfoGroup.(rType{1}){g};
            unitData = cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id);
            maxFiringRate = max(unitData.psthSmoothed);
            
            % Separate max rates by group
            if strcmp(unitInfo.group, 'Emx')
                emxRates = [emxRates; maxFiringRate];
            elseif strcmp(unitInfo.group, 'Pvalb')
                pvalbRates = [pvalbRates; maxFiringRate];
            end
        end

        % Calculate IQR, median, and upper fence for extreme outliers (k=3.0)
        if ~isempty(emxRates)
            Q1_emx = quantile(emxRates, 0.25);
            Q3_emx = quantile(emxRates, 0.75);
            IQR_emx = Q3_emx - Q1_emx;
            upperFence_emx = Q3_emx + 3.0 * IQR_emx;  % Strict threshold for extreme outliers

            groupIQRs.(rType{1}).Emx.IQR = IQR_emx;
            groupIQRs.(rType{1}).Emx.Median = median(emxRates);
            groupIQRs.(rType{1}).Emx.UpperFence = upperFence_emx;
        end

        if ~isempty(pvalbRates)
            Q1_pvalb = quantile(pvalbRates, 0.25);
            Q3_pvalb = quantile(pvalbRates, 0.75);
            IQR_pvalb = Q3_pvalb - Q1_pvalb;
            upperFence_pvalb = Q3_pvalb + 3.0 * IQR_pvalb;

            groupIQRs.(rType{1}).Pvalb.IQR = IQR_pvalb;
            groupIQRs.(rType{1}).Pvalb.Median = median(pvalbRates);
            groupIQRs.(rType{1}).Pvalb.UpperFence = upperFence_pvalb;
        end
    end

    % Flag outliers based on the strict IQR threshold
    for rType = responseTypes
        for g = 1:length(unitInfoGroup.(rType{1}))
            unitInfo = unitInfoGroup.(rType{1}){g};
            unitData = cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id);
            maxFiringRate = max(unitData.psthSmoothed);

            if strcmp(unitInfo.group, 'Emx') && maxFiringRate > groupIQRs.(rType{1}).Emx.UpperFence
                cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = true;
            elseif strcmp(unitInfo.group, 'Pvalb') && maxFiringRate > groupIQRs.(rType{1}).Pvalb.UpperFence
                cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = true;
            end
        end
    end

    % Pass cellDataStruct and IQRs to the plotting function if plotOutliers is true
    if plotOutliers
        plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, groupIQRs);
    end
end
