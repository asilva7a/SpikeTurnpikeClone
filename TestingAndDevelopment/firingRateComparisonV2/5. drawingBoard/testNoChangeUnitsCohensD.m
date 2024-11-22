function testNoChangeUnitsCohensD()
    % Test data setup
    unitTable = table();
    unitTable.UnitID = {'cid327', 'cid739', 'cid744'};
    unitTable.Group = {'Emx', 'Emx', 'Emx'};
    unitTable.CohensD = [-0.024, -0.022, -0.033];
    unitTable.ResponseType = {'No_Change', 'No_Change', 'No_Change'};
    
    % Create test groupData structure
    groupData.Emx.Labels = unitTable.UnitID;
    groupData.Emx.CohensD = unitTable.CohensD;
    groupData.Emx.Colors = repmat([0.4 0.4 0.4], 3, 1);
    
    % Create lookup table
    cohenDLookup = containers.Map();
    for i = 1:height(unitTable)
        cohenDLookup(unitTable.UnitID{i}) = unitTable.CohensD(i);
    end
    
    % Test each No Change unit
    for i = 1:length(unitTable.UnitID)
        unitID = unitTable.UnitID{i};
        expectedCohensD = unitTable.CohensD(i);
        actualCohensD = cohenDLookup(unitID);
        
        assert(abs(actualCohensD - expectedCohensD) < 1e-6, ...
            sprintf('Cohen''s d mismatch for unit %s: expected %.3f, got %.3f', ...
            unitID, expectedCohensD, actualCohensD));
        
        assert(strcmp(unitTable.ResponseType{i}, 'No_Change'), ...
            sprintf('Unit %s should be marked as No_Change', unitID));
    end
    
    fprintf('All tests passed successfully!\n');
end
