function maxproj_maskboundary = ComputeMaxProjMaskBoundary(maskdata,dim,z0,z1,y0,y1)

if nargin < 2,
  dim = 3;
end
if nargin < 3 || isempty(z0),
  z0 = 1;
end
if nargin < 4 || isempty(z1),
  z1 = size(maskdata.mask_symmetric,3);
end
if nargin < 5 || isempty(y0),
  y0 = 1;
end
if nargin < 6 || isempty(y1),
  y1 = size(maskdata.mask_symmetric,2);
end
nd = ndims(maskdata.mask_symmetric);
per = [1:dim-1,dim+1:nd,dim];

tmp = permute(any(maskdata.mask_symmetric(:,y0:y1,z0:z1),dim),per);
maxproj_maskboundary = bwboundaries(tmp,'noholes');
