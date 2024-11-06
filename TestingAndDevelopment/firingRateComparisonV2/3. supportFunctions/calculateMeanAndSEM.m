function [avgPSTH, semPSTH] = calculateMeanAndSEM(psthData)
    % calculateMeanAndSEM: Helper function for poolResponsiveUnitsAndCalculatePSTH.
    % Calculates the mean and standard error of the mean (SEM) for the PSTH data across units.
    %
    % Called by:
    %   - poolResponsiveUnitsAndCalculatePSTH
    %
    % Inputs:
    %   - psthData: Matrix where each row is a PSTH for a unit, and each column is a time bin.
    %
    % Outputs:
    %   - avgPSTH: Average PSTH across units.
    %   - semPSTH: Standard error of the mean across units.

    % Remove empty rows (NaNs from preallocation) before calculation
    psthData = psthData(~all(isnan(psthData), 2), :);

    % Calculate mean and SEM
    avgPSTH = mean(psthData, 1, 'omitnan');
    semPSTH = std(psthData, 0, 1, 'omitnan') / sqrt(size(psthData, 1));
end
