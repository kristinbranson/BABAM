% res = ComputeBehaviorAnatomyMap_Logic(cmds,normbehaviordata_plus,normbehaviordata_minus,behaviorlabels,...)
% res = ComputeBehaviorAnatomyMap_Logic(cmds,datafile)
% res = ComputeBehaviorAnatomyMap_Logic(cmds)
function res = ComputeBehaviorAnatomyMap_Logic(cmds,normbehaviordata_plus,varargin)

res = [];

if ~iscell(cmds),
  cmds = {cmds};
end

% load in data if not input

persistent prevdatafile;
persistent prevdatafile_datenum;
persistent prevdata;
if isempty(prevdatafile),
  prevdatafile = '';
end
if isempty(prevdatafile_datenum),
  prevdatafile_datenum = -1;
end

if nargin < 2,
  normbehaviordata_plus = '';
end

if ischar(normbehaviordata_plus),
  datafile = normbehaviordata_plus;
  if isempty(datafile),
    datafile = uigetfile('*.mat','Select mat file containing normalized behavior data',prevdatafile);
    if ~ischar(datafile),
      return;
    end
    fileinfo = dir(datafile);
    if isempty(fileinfo),
      warning('File %s does not exist',datafile);
      return;
    end
  end
  doload = true;
  if strcmp(prevdatafile,datafile) && ~isempty(prevdata),
    if fileinfo.datenum <= prevdatafile_datenum,
      doload = false;
    end
  end
  if doload,
    prevdata = load(datafile);
    prevdata.prevdatafile_datenum = fileinfo.datenum;
    prevdatafile = datafile;
  end
  normbehaviordata_plus = prevdata.normbehaviordata_plus;
  normbehaviordata_minus = prevdata.normbehaviordata_minus;
  behaviorlabels = prevdata.behaviorlabels;

else
  
  normbehaviordata_minus = varargin{1};
  behaviorlabels = varargin{2};
  varargin = varargin(3:end);

end

normbehaviordata = nan(size(normbehaviordata_plus,1),numel(cmds));
behaviorfns = cell(1,numel(cmds));
stattypes = cell(1,numel(cmds));
for i = 1:numel(cmds),
  [normbehaviordata(:,i),behaviorfns{i},stattypes{i}] = ComputeNormBehaviorData_Logic(cmds{i},normbehaviordata_plus,normbehaviordata_minus,behaviorlabels,varargin{:});
end

res = ComputeBehaviorAnatomyMap(normbehaviordata,cmds,varargin{:});
res.normbehaviordata = normbehaviordata;
res.behaviorfns = behaviorfns;
res.stattypes = stattypes;