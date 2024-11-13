function [cellDataStruct,sparseUnitsList] = tagSparseUnits(cellDataStruct, minFrRate, frBefore)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
preTreatmentFr = frBefore;



if preTreatmentFr > minFrRate
    unitID.isSparseUnit = 1;
else 
    unitID.isSparseUnit = 0;
end


end