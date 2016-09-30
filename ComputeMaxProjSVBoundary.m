function maxproj_svboundary = ComputeMaxProjSVBoundary(labels,sv,dim,z0,z1,y0,y1)

if nargin < 3,
  dim = 3;
end
nd = ndims(labels);
per = [1:dim-1,dim+1:nd,dim];
if nargin < 4 || isempty(z0),
  z0 = 1;
end
if nargin < 5 || isempty(z1),
  z1 = size(labels,3);
end

if nargin < 6 || isempty(y0),
  y0 = 1;
end
if nargin < 7 || isempty(y1),
  y1 = size(labels,1);
end

tmp = permute(any(labels(y0:y1,:,z0:z1)==sv,dim),per);
maxproj_svboundary = bwboundaries(tmp,'noholes');
