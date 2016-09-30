function [order,csfracba,fracba] = FindImporantLinesForSupervoxels(svdata,normbehaviordata)

% how much of the total ba for these supervoxels does each line explain
fracba = sum(svdata,2).*normbehaviordata;
fracba = fracba / sum(fracba);

% sort lines by ba explained
[~,order] = sort(fracba,1,'descend');
csfracba = cumsum(fracba(order));
