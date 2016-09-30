function [compartmentslices,maxprojslices] = ComputeCompartmentBoundariesPerSlice(maskdata,z0s,z1s,dir,permutemask)

if ~exist('permutemask','var'),
  permutemask = false;
end

nslices = numel(z0s);
maxprojslices = cell(1,nslices);
compartmentslices = cell(1,nslices);
if permutemask,
  mask = permute(maskdata.mask,[2,1,3,4]);
  mask_symmetric = maskdata.mask_symmetric;
else
  mask = maskdata.mask;
  mask_symmetric = permute(maskdata.mask_symmetric,[2,1,3,4]);
end
imsz = size(mask);

if nargin < 4,
  dir = 3;
end

args = cell(1,3);
for i = 1:3,
  args{i} = 1:imsz(i);
end
imoutsz = imsz;
imoutsz(dir) = [];

for i = 1:nslices,
  zcurr = round((z0s(i)+z1s(i))/2);
  args1 = args;
  args2 = args;
  args1{dir} = zcurr;
  args2{dir} = z0s(i):z1s(i);
  for j = 1:numel(maskdata.leg),
    compartmentslices{i}{j} = bwboundaries(reshape(any(mask(args1{:})==j,dir),imoutsz));
  end
  maxprojslices{i} = bwboundaries(reshape(any(mask_symmetric(args2{:}),dir),imoutsz),'noholes');
end
