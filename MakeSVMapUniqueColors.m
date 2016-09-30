function Irgb2 = MakeSVMapUniqueColors(maxproj,maxidx,cm,clim,labels,dir,ignoreidx)

if ~exist('dir','var'),
  dir = 3;
end
if ~exist('ignoreidx','var'),
  ignoreidx = false(size(maxidx));
end

nsvs = max(labels(:));
tmp = maxproj;
tmp(isnan(maxproj)) = clim(1);
ncmcolors = size(cm,1);
coloridx = RescaleToIndex(tmp,ncmcolors,clim(1),clim(2));
switch dir,
  case 3,
    supervoxelidx = labels(sub2ind([size(labels,1)*size(labels,2),size(labels,3)],...
      1:size(labels,1)*size(labels,2),maxidx(:)'));
  case 2,
    [tmpz,tmpx] = meshgrid(1:size(labels,3),1:size(labels,1));
    supervoxelidx = labels(sub2ind([size(labels,1),size(labels,2),size(labels,3)],...
      tmpx(:),maxidx(:),tmpz(:)));
  case 1,
    [tmpz,tmpy] = meshgrid(1:size(labels,3),1:size(labels,2));
    supervoxelidx = labels(sub2ind([size(labels,1),size(labels,2),size(labels,3)],...
      maxidx(:),tmpy(:),tmpz(:)));
end
    
svcolor = ones(1,nsvs);
for colori = 1:ncmcolors,
%   if (colori == 1 && dologcmap) || (colori == ncmcolors && ~dologcmap),
%     continue;
%   end
  svidxcurr = unique(supervoxelidx(coloridx==colori));
  svidxcurr(svidxcurr==0) = [];
  nsvspercolor = numel(svidxcurr);
  if nsvspercolor <= 1,
    continue;
  end
  colorscurr = linspace(.75,1,nsvspercolor);
  colorscurr = colorscurr(randperm(nsvspercolor));
  svcolor(svidxcurr) = colorscurr;
end
Irgb = colormap_image(maxproj,cm,clim);
sz = size(labels);
sz(dir) = [];
Igray = ones(sz);
Igray(supervoxelidx>0) = svcolor(supervoxelidx(supervoxelidx>0));
Igray(ignoreidx) = 1;
Irgb2 = bsxfun(@times,Irgb,Igray);