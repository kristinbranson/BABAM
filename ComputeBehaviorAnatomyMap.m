function res = ComputeBehaviorAnatomyMap(normbehaviordata,behaviorlabels,varargin)

res = struct;

%% parse inputs
timestamp = datestr(now,'yyyymmddTHHMMSSFFF');

[matfile,fdr_alpha,...
  plotadjusted,maxpvalue,minpvalue,dologcmap,nslices,...
  usecluster,nsamplestotal,nsamplesperbatch,scriptdir,timestamp,...
  hfigs,doplot] = ...
  myparse(varargin,'matfile','/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/ComputeBehaviorAnatomyMapData_ms_centers0.750000_w0.000010_r2_20150202.mat',...
  'fdr_alpha',.25,...
  'plotadjusted',false,...
  'maxpvalue',[],'minpvalue',[],...
  'dologcmap',true,'nslices',3,...
  'usecluster',false,...
  'nsamplestotal',1000,...
  'nsamplesperbatch',1000,...
  'scriptdir','',...
  'timestamp',timestamp,...
  'hfigs',[],...
  'doplot',true);

if usecluster && isempty(scriptdir),
  scriptdir = sprintf('/nobackup/branson/pv%s',timestamp);
  if ~exist(scriptdir,'dir'),
    mkdir(scriptdir);
  end
  if ~exist(scriptdir,'dir'),
    error('Could not create directory %s',scriptdir);
  end
end

if isempty(minpvalue),
  if dologcmap,
    minpvalue = .0001;
  else
    minpvalue = 0;
  end
end

%% load cached data

persistent prevmatfile;
persistent supervoxeldata; %#ok<USENS>
persistent labels; %#ok<USENS>
persistent maskdata; %#ok<USENS>
doload = false;

if isempty(prevmatfile) || ~strcmp(prevmatfile,matfile) || ...
    isempty(supervoxeldata) || isempty(labels) || isempty(maskdata),
  doload = true;
  load(matfile,'supervoxeldata');
  prevmatfile = matfile;  
end

res.matfile = matfile;
res.supervoxeldata = supervoxeldata;

%% compute behavior-anatomy index
res.baindex = ComputeBAIndex(normbehaviordata,supervoxeldata);

%% compute p-values

[res.pvalue] = ...
  ComputeBehaviorAnatomyCorrPValues_asymm(normbehaviordata,...
  supervoxeldata,res.baindex,...
  nsamplestotal,...
  'usecluster',usecluster,'nsamplesperbatch',nsamplesperbatch,...
  'tmpdir',scriptdir,'timestamp',timestamp,'doclean',true);

%% correct for fdr
res.qvalue = nan(size(res.pvalue));
h_plus = false(size(res.pvalue));
for i = 1:size(res.pvalue,2),
  [h,~,adj_p] = fdr_bh(res.pvalue(:,i),fdr_alpha,'pdep');
  %adj_p(~h) = 1;
  res.qvalue(:,i) = adj_p;
  h_plus(:,i) = h;
end

res.pvalue_fdr = res.pvalue;
res.pvalue_fdr(~h_plus) = 1;

if plotadjusted,
  pvalue_plot = res.qvalue;
  if isempty(maxpvalue),
    maxpvalue = fdr_alpha+.001;
  end
else
  pvalue_plot = res.pvalue_fdr;
  if isempty(maxpvalue),
    maxpvalue = .051;
  end
end

%% reproject

if doplot,

  if doload,
    load(matfile,'labels','maskdata');
  end

  res.behaviormaps = cell(numel(behaviorlabels),1);
  clims = cell(numel(behaviorlabels),1);
  res.imouts = cell(numel(behaviorlabels),1);
  res.imoutxs = cell(numel(behaviorlabels),1);
  maxprojslices = cell(numel(behaviorlabels),1);
  maxprojslicesx = cell(numel(behaviorlabels),1);
  
  for stati = 1:numel(behaviorlabels),
    if numel(hfigs) >= 2*stati,
      hfigscurr = hfigs(2*stati-1:2*stati);
    else
      hfigscurr = [];
    end
    
    behaviorname = behaviorlabels{stati};
    behaviorname(1) = upper(behaviorname(1));
    figtitle = behaviorname;
    
    [hfigs(2*stati-1:2*stati),res.behaviormaps{stati,1},clims{stati,1},...
      res.imouts{stati,1},res.imoutxs{stati,1},maxprojslices{stati,1},maxprojslicesx{stati,1}] = ...
      PlotBehaviorAnatomyMap(pvalue_plot(:,stati),labels,...
      'figtitle',figtitle,'minpvalue',minpvalue,...
      'maxpvalue',maxpvalue','dologcmap',dologcmap,...
      'hfigs',hfigscurr,'maskdata',maskdata,'nslices',nslices);
    
  end
  
  res.hfigs = hfigs;
  
end