function [pvalue,nsmaller,sample_baindex] = ...
  ComputePValueBehaviorAnatomySupervoxel_asymm(normbehaviordata,supervoxeldata_t,baindex,nsamples,dosavesamples,nsmaller,nsamples0)

if ischar(normbehaviordata),
  matfilename = normbehaviordata;
  savename_iter = supervoxeldata_t;
  load(matfilename);
end

if ~exist('dosavesamples','var'),
  dosavesamples = false;
end

if isdeployed,
  rnginfo = rng('shuffle');
else
  rnginfo = [];
end

% normbehaviordata_reshape is nlines x 1 x nstats
% supervoxeldata is nlines x nsupervoxels

nsupervoxels = size(supervoxeldata_t,1);
nstatscurr = size(normbehaviordata,2);
nlinescurr = size(supervoxeldata_t,2);

if ~exist('nsamples','var'),
  nsamples = 1000;
end

if exist('nsmaller','var') && exist('nsamples0','var') && ...
    ~isempty(nsmaller) && nsamples0 > 0,
else
  nsmaller = zeros([nsupervoxels,nstatscurr],'single');
  nsamples0 = 0;
end

if dosavesamples,
  sample_baindex = zeros([nsupervoxels,nstatscurr,nsamples],'single');
else
  sample_baindex = [];
end  


supervoxeldata_sum = sum(supervoxeldata_t,2);

for samplei = 1:nsamples,

  if mod(samplei,100) == 0,
    fprintf('Sample %d/%d\n',samplei,nsamples);
    drawnow;
  end

  % sample with replacement from all lines
  r = randsample(nlinescurr,nlinescurr,true)';
  
%   % sample with replacement from all lines except this one
%   r = randsample(nlinescurr-1,nlinescurr,true)';
%   idx = r >= 1:nlinescurr;
%   r(idx) = r(idx)+1;
  
  normbehaviordata_curr = normbehaviordata(r,:);

  normbehaviordata_sum = sum(normbehaviordata_curr,1);
  
  baintersection0 = supervoxeldata_t*normbehaviordata_curr;
  baunion = bsxfun(@plus,normbehaviordata_sum,supervoxeldata_sum);
  baindex0 = baintersection0./baunion*2;
  
  idx = bsxfun(@lt,baindex0,baindex);
  nsmaller(idx) = nsmaller(idx) + 1;
  
  if dosavesamples,
    sample_baindex(:,:,samplei) = baindex0;
  end

  
end

pvalue = 1 - nsmaller/(nsamples+nsamples0);

if exist('matfilename','var'),
  nsamples0 = nsamples + nsamples0; %#ok<NASGU>
  [p,n,~] = fileparts(matfilename);
  if exist('savename_iter','var'),
    nt = savename_iter;
  else
    [~,nt] = fileparts(tempname);
  end
  savefile = fullfile(p,sprintf('%s_samples%s_%s.mat',n,datestr(now,'yyyymmddTHHMMSSFFF'),nt));
  if dosavesamples,
    save(savefile,'pvalue','nsmaller','nsamples0','rnginfo','sample_baindex');
  else
    save(savefile,'pvalue','nsmaller','nsamples0','rnginfo');
  end
end