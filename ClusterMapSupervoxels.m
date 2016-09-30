function res = ClusterMapSupervoxels(bamap,k,varargin)

res = struct;
res.success = false;
nsvstotal = size(bamap.supervoxeldata,2);

[pvalthresh,behthresh,anatthresh,savedata] = myparse(varargin,'pvalthresh',.01,'behthresh',.5,'anatthresh',.5,'savedata',struct);

res.svidx = find(bamap.pvalue <= pvalthresh);
if isempty(res.svidx),
  return;
end
nsvscluster = numel(res.svidx);

res.lineidx = bamap.normbehaviordata >= behthresh & any(bamap.supervoxeldata(:,res.svidx)>=anatthresh,2);
if nnz(res.lineidx)==0,
  return;
end

usesavedata = false;
if isstruct(savedata) && all(isfield(res,{'svidx','lineidx','Z'})) && ...
    nsvscluster == numel(savedata.svidx) && ...
    all(res.svidx(:)==savedata.svidx(:)) && ...
    numel(res.lineidx) == numel(savedata.lineidx) && ...
    all(res.lineidx(:)==savedata.lineidx(:)),
  usesavedata = true;
  res = savedata;
end

if ~usesavedata,
  X = bamap.supervoxeldata(res.lineidx,res.svidx);
  Z = linkage(X','average','cityblock');
end

res.clusterid0 = cluster(Z,'MaxClust',k);

% sort by number of members so that big clusters have lower indices
counts = hist(res.clusterid0,1:k);
[~,order] = sort(counts,'descend');
[~,order] = sort(order);
res.clusterid0 = order(res.clusterid0);

res.clusterid = zeros(1,nsvstotal);
res.clusterid(res.svidx) = res.clusterid0;

res.success = true;