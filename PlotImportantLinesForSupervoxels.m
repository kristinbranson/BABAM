function [hfig_showlines,hax_showlines,...
  hfig_showlineaverage,hax_showlineaverage] = ...
  PlotImportantLinesForSupervoxels(imdata,line_names_show,varargin)

[computeavemethod,hfig_showlines,hfig_showlineaverage,labels,supervoxeldata,SetStatusFcn,anatomydir,isflylightdir] = ...
  myparse(varargin,'computeavemethod','',...
  'hfig_showlines',[],'hfig_showlineaverage',[],'labels',[],'supervoxeldata',[],'SetStatusFcn',@fprintf,...
  'anatomydir','','isflylightdir',true);
hax_showlineaverage = [];

nlinesshow = numel(line_names_show);

isflylightwebsiteinfo = isfield(imdata,'maxproj_url');
if isflylightwebsiteinfo,
  isonweb = ~cellfun(@isempty,{imdata.maxproj_url});
end

% create figure
if isempty(hfig_showlines) || ~ishandle(hfig_showlines);
  hfig_showlines = figure;
else
  clf(hfig_showlines);
end  

% show max projections

% create axes
nax = nlinesshow+1;
nr = ceil(sqrt(nax));
nc = ceil(nax/nr);
hax_showlines = createsubplots(nr,nc,.01,hfig_showlines);
hax_showlines = reshape(hax_showlines,[nr,nc])';
delete(hax_showlines(nlinesshow+1:end));
hax_showlines = hax_showlines(1:nlinesshow);

% show the max projection images
didplot = false(1,nlinesshow);
for i = 1:nlinesshow,

  % find images of this line
  if ~isflylightdir && isflylightwebsiteinfo,
    idxanat = find(isonweb & strcmp({imdata.line},line_names_show{i}));
  else
    idxanat = find(strcmp({imdata.line},line_names_show{i}));
  end
  
  % sort by qi
  [~,order2] = sort([imdata(idxanat).qi]);
  
  % find registered max proj images
  reg_file = '';
  for j = idxanat(order2)',
    if ~isflylightdir && isflylightwebsiteinfo,
      reg_file = imdata(j).reg_file_url;
    else
      reg_file = GetRegMaxProjFile(imdata(j));
    end
    if ~isempty(reg_file),
      break;
    end
  end
  
  % if not registered, find original max proj images
  if isempty(reg_file),
    for j = idxanat(order2)',
      if ~isflylightdir && isflylightwebsiteinfo,
        reg_file = imdata(j).maxproj_url;
      else
        reg_file = imdata(j).maxproj_file_system_path;
        if ~exist(reg_file,'file'),
          reg_file = '';
        end
      end
      if ~isempty(reg_file),
        break;
      end
    end
  end

  % plot
  if ~isempty(reg_file),
    try
      im = imread(reg_file);
      image(im,'Parent',hax_showlines(i));
      axis(hax_showlines(i),'image','off');
      didplot(i) = true;
    end
  end
  
end

linkaxes(hax_showlines(didplot));
if ~all(didplot),
  delete(hax_showlines(~didplot));
end


if isempty(computeavemethod) && isempty(supervoxeldata),
  computeavemethod = 'True';
elseif isempty(computeavemethod) && (isempty(anatomydir) || ~exist(anatomydir,'dir')),
  computeavemethod = 'Supervoxel';
end
if isempty(computeavemethod),
  computeavemethod = questdlg('Show supervoxel-based average (less slow) or true average (slow)?',...
    'Line average type','Supervoxel','True','Cancel','Supervoxel');
end
if strcmpi(computeavemethod,'Cancel'),
  return;
end

% create figure for average
if isempty(hfig_showlineaverage) || ~ishandle(hfig_showlineaverage);
  hfig_showlineaverage = figure;
else
  clf(hfig_showlineaverage);
end

hax_showlineaverage = createsubplots(nr,nc,.01,hfig_showlineaverage);
hax_showlineaverage = reshape(hax_showlineaverage,[nr,nc])';
delete(hax_showlineaverage(nlinesshow+2:end));
hax_showlineaverage = hax_showlineaverage(1:nax);

if strcmpi(computeavemethod,'Supervoxel'),

  meanimcurr = nan(size(labels),'single');
  meanimcurr(labels>0) = mean(supervoxeldata(:,labels(labels>0)),1);
  
elseif strcmpi(computeavemethod,'True'),
  
  SetStatusFcn('Reading in line %d / %d...',1,nlinesshow);
  i = 1;
  filename = fullfile(anatomydir,sprintf('meanim_%s.mat',line_names_show{i}));
  tmp = load(filename,'meanim');
  imcurr = repmat(permute(tmp.meanim,[2,1,3]),[1,1,1,nlinesshow]);
  for i = 2:nlinesshow,
    SetStatusFcn('Reading in line %d / %d...',i,nlinesshow);
    filename = fullfile(anatomydir,sprintf('meanim_%s.mat',line_names_show{i}));
    tmp = load(filename,'meanim');
    imcurr(:,:,:,i) = permute(tmp.meanim,[2,1,3]);
  end
  meanimcurr = mean(imcurr,4);
end

imagesc(max(meanimcurr,[],3),'Parent',hax_showlineaverage(nax),[0,1]);
axis(hax_showlineaverage(nax),'image','off');
colormap(hax_showlineaverage(nax),kjetsmooth(256));
if verLessThan('matlab','8.4.0'),
  colorbar('peer',hax_showlineaverage(nax),'East');
else
  colorbar('peer',handle(hax_showlineaverage(nax)),'East');
end
drawnow;
  
for i = 1:nlinesshow,
    
  if strcmpi(computeavemethod,'Supervoxel'),
    imcurr = nan(size(labels),'single');
    imcurr(labels>0) = supervoxeldata(i,labels(labels>0));
    imcurr = meanimcurr .* imcurr;
    imagesc(max(imcurr,[],3),'Parent',hax_showlineaverage(i),[0,1]);
  else
    imagesc(max(meanimcurr.*imcurr(:,:,:,i),[],3),'Parent',hax_showlineaverage(i),[0,1]);
  end
  axis(hax_showlineaverage(i),'image','off');
  colormap(hax_showlineaverage(i),kjetsmooth(256));
  % TODO: move to main function
%   text(5,5,sprintf('%s: (beh = %.1f) * (anat = %.1f) -> (index = %.1f)',...
%     line_names_show{i},...
%     handles.bamap.normbehaviordata(i),...
%     supervoxeldata(i,supervoxelid),...
%     handles.bamap.normbehaviordata(i)*supervoxeldata(i,supervoxelid)),...
%     'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
%     'Interpreter','none','Parent',hax_showlineaverage(i));
  drawnow;
end

impixelinfo(hfig_showlineaverage);
linkaxes(hax_showlineaverage);
