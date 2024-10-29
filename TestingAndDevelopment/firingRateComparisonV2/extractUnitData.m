function extractUnitData [outputArg1,outputArg2] = extractUnitData(inputArg1,inputArg2);
%extractUnitData 
%   Does what is says on the box
%   Pulls out the firing rate from the all_data struct for one unit

% Pre-load original cell data
load('all_data')

cellData = all_data.e;


outputArg2 = inputArg2;
end