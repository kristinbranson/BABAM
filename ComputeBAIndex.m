function [baindex,baintersection,baunion] = ComputeBAIndex(normbehaviordata,supervoxeldata)

baintersection = supervoxeldata'*normbehaviordata;
baunion = bsxfun(@plus,sum(normbehaviordata,1),sum(supervoxeldata,1)');
baindex = baintersection./baunion*2;
