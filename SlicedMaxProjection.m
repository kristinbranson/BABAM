function [imout,z0s,z1s,idx] = SlicedMaxProjection(im,nslices,varargin)

[fun,dir,maxslicewidth,z0s,z1s] = myparse(varargin,...
  'fun','max','dir',3,'maxslicewidth',inf,'z0s',[],'z1s',[]);

imsz = size(im);

if numel(imsz) < 4,
  imsz(4) = 1;
end

if isempty(z0s),
  
  zs = round(linspace(1,imsz(dir)+1,nslices+1));
  if isinf(maxslicewidth),
    z0s = zs(1:end-1);
    z1s = zs(2:end)-1;
  else
    zmids = (zs(1:end-1)+zs(2:end))/2;
    r = (maxslicewidth-1)/2;
    z0s = round(zmids-r);
    z1s = round(zmids+r);
  end

end

imoutsz = [imsz,nslices];
imoutsz(dir) = [];

imout = zeros(imoutsz,class(im));
idx = nan(imoutsz);

argsin = cell(1,4);
for i = 1:4,
  argsin{i} = 1:imsz(i);
end

for i = 1:nslices,
  argsin{dir} = z0s(i):z1s(i);
  switch fun,
    case 'max',
      [imout(:,:,:,i),idx(:,:,:,i)] = max(im(argsin{:}),[],dir);
    case 'min',
      [imout(:,:,:,i),idx(:,:,:,i)] = min(im(argsin{:}),[],dir);
    case 'mean',
      imout(:,:,:,i) = mean(im(argsin{:}),dir);
    otherwise
      error('Unknown function %s',fun);
  end
  idx(:,:,:,i) = idx(:,:,:,i) + z0s(i)-1;
end
