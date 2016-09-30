function [hfigs,behaviormap,clim,imout,imoutx,maxprojslices_out,maxprojslicesx_out] = PlotBehaviorAnatomyMap(pvalue,labels,varargin)

[dologcmap,nslices,minpvalue,maxpvalue,pvalueslabel,pvaluelabels,...
  figtitle,hfigs,maskdata,nslicesx,maxslicewidth,x0s,x1s,z0s,z1s,makeuniquesvcolors,...
  xslices,yslices,zslices,umperpx,dtick,colordepth,darkbkgd] = ...
  myparse(varargin,'dologcmap',true,'nslices',3,...
  'minpvalue',[],'maxpvalue',.051,...
  'pvaluleslabel',[],'pvaluelabels',{},...
  'figtitle','','hfigs',[],'maskdata',[],'nslicesy',0,'maxslicewidth',inf,...
  'x0s',[],'x1s',[],'z0s',[],'z1s',[],...
  'makeuniquesvcolors',false,...
  'xslices',[],'yslices',[],'zslices',[],'umperpx',1,'dtick',[],...
  'colordepth',false,'darkbkgd',true);

% min pvalue for colormap
if isempty(minpvalue),
  if dologcmap,
    minpvalue = .0001;
  else
    minpvalue = 0;
  end
end

% pvalues to label on the colorbar
if isempty(pvalueslabel),
  pvalueslabel = [.0001,.001,.01,.05,.1,.25];
  pvaluelabels = {'.0001','.001','.01','.05','.1','.25'};
  idxremove = pvalueslabel < minpvalue | pvalueslabel > maxpvalue;
  pvalueslabel(idxremove) = [];
  pvaluelabels(idxremove) = [];
end
if isempty(pvaluelabels),
  pvaluelabels = strtrim(cellstr(num2str(pvalueslabel(:))));
  pvaluelabels = regexprep(pvaluelabels,'^0.','.');
end

%% plot max projection

persistent maxproj_maskboundary;

% mask info
if ~isempty(maskdata),
  if isempty(maxproj_maskboundary),
    maxproj_maskboundary = ComputeMaxProjMaskBoundary(maskdata);
  end
end

if isempty(hfigs),
  hfigs(1) = figure;
elseif ~ishandle(hfigs(1)),
  figure(hfigs(1));
else
  set(0,'CurrentFigure',hfigs(1));
  clf;
end
set(hfigs(1),'Units','pixels','Position',[10,10,1389,836],'Color','w');
hax = axes('Position',[.01,.01,.98,.98]);
axes(hax);
ncmcolors = 256;
cm_depth = myredbluecmap_constantv(ncmcolors);
if dologcmap,
  behaviormap = BehaviorAnatomyMap(max(0,log10(maxpvalue)-log10(pvalue)),labels,nan);
  clim = [0,log10(maxpvalue)-log10(minpvalue)];
  if colordepth,
    if darkbkgd,
      cm = gray(ncmcolors);
    else
      cm = flipud(gray(ncmcolors));
    end
  elseif darkbkgd,
    cm = kjet(ncmcolors);
  else
    cm = wjet(ncmcolors);
  end
  [maxproj,maxidx] = max(behaviormap,[],3);
else
  behaviormap = BehaviorAnatomyMap(pvalue,labels,1);
  clim = [minpvalue,maxpvalue];
  if colordepth,
    if darkbkgd,
      cm = flipud(gray(ncmcolors));
    else
      cm = gray(ncmcolors);
    end
  elseif darkbkgd,
    cm = flipud(kjet(ncmcolors));
  else
    cm = flipud(wjet(ncmcolors));
  end
  [maxproj,maxidx] = min(behaviormap,[],3);
end

imsz = size(labels);
xlim = [1,imsz(1)]*umperpx;
ylim = [1,imsz(2)]*umperpx;
zlim = [1,imsz(3)]*umperpx;
xtextoff = 5*umperpx;

if ~isempty(dtick),
  
  xticks = ceil(xlim(1)/dtick)*dtick:dtick:floor(xlim(2)/dtick)*dtick;
  yticks = ceil(ylim(1)/dtick)*dtick:dtick:floor(ylim(2)/dtick)*dtick;
  zticks = ceil(zlim(1)/dtick)*dtick:dtick:floor(zlim(2)/dtick)*dtick;
  
end

if colordepth,

  imagesc(0,zlim);
  hold(gca,'on');
  
  Irgb = colormap_image(maxidx*umperpx,cm_depth,zlim);
  Igray = colormap_image(maxproj,cm,clim);
  Irgb = Irgb .* Igray;
  Irgb = permute(Irgb,[2,1,3]);
  image(xlim,ylim,Irgb);
  colormap(cm_depth);
  set(gca,'CLim',zlim);
  
else
  if makeuniquesvcolors,
    
    imagesc(0,clim);
    hold(gca,'on');
    
    if dologcmap,
      ignoreidx = maxproj <= clim(1);
    else
      ignoreidx = maxproj >= clim(2);
    end
    Irgb = MakeSVMapUniqueColors(maxproj,maxidx,cm,clim,labels,3,ignoreidx);
    Irgb = permute(Irgb,[2,1,3]);
    image(xlim,ylim,Irgb);
    
  else
    imagesc(xlim,ylim,maxproj',clim);
  end
  colormap(cm);
  set(gca,'CLim',clim);

end

axis image;
if darkbkgd,
  boundarycolor = [1,1,1];
else
  boundarycolor = [0,0,0];
end
if ~isempty(maxproj_maskboundary),
  hold on;
  for tmpi = 1:numel(maxproj_maskboundary),
    plot(maxproj_maskboundary{tmpi}(:,1)*umperpx,maxproj_maskboundary{tmpi}(:,2)*umperpx,'-','Color',boundarycolor);
  end
end

if ~isempty(dtick),
  set(gca,'XTick',xticks,'YTick',yticks);
end

cb = colorbar;
if ~colordepth && dologcmap,
  set(cb,'YTick',log10(maxpvalue)-log10(fliplr(pvalueslabel)),'YTickLabel',fliplr(pvaluelabels));
end
if ~isempty(figtitle),
  title(figtitle,'Interpreter','none');
end
set(hfigs(1),'InvertHardcopy','off');

drawnow;

%% plot slice projections

persistent compartmentslices maxprojslices compartmentslicesx maxprojslicesx;

imoutx = [];
imout = [];
maxprojslices_out = [];
maxprojslicesx_out = [];

if ~isempty(z0s),
  nslices = numel(z0s);
end
if ~isempty(x0s),
  nslicesx = numel(x0s);
end

if nslices > 0 || nslicesx > 0,

if numel(hfigs) < 2,
  hfigs(2) = figure;
elseif ~ishandle(hfigs(2)),
  figure(hfigs(2));
else
  set(0,'CurrentFigure',hfigs(2));
  clf;
end
set(hfigs(2),'Color','w','Units','pixels','Position',[20 20 966 1466]);

if dologcmap,
  fun = 'max';
else
  fun = 'min';
end
[imout,z0s,z1s,maxidx] = SlicedMaxProjection(behaviormap,nslices,'fun',fun,'dir',3,'maxslicewidth',maxslicewidth,'z0s',z0s,'z1s',z1s);

if nslicesx > 0,
  [imoutx,x0s,x1s,maxidxx] = SlicedMaxProjection(behaviormap,nslices,'fun',fun,'dir',2,'maxslicewidth',maxslicewidth,'z0s',x0s,'z1s',x1s);
end  

% mask info
if ~isempty(maskdata),
  if isempty(compartmentslices) || numel(compartmentslices) ~= nslices,
    [compartmentslices,maxprojslices] = ComputeCompartmentBoundariesPerSlice(maskdata,z0s,z1s,3);
  end
  if nslicesx > 0 && isempty(compartmentslicesx) || numel(compartmentslicesx) ~= nslicesx,
    [compartmentslicesx,maxprojslicesx] = ComputeCompartmentBoundariesPerSlice(maskdata,x0s,x1s,1);
  end
end

if darkbkgd,
  compartmentboundarycolor = [.7,.7,.7];
else
  compartmentboundarycolor = [.3,.3,.3];
end

hax = createsubplots(nslices+nslicesx,1,0);
for i = 1:nslices,
  if makeuniquesvcolors,  
    imagesc(0,'Parent',hax(i),clim);
    hold(hax(i),'on');
    
    if dologcmap,
      ignoreidx = imout(:,:,:,i) <= clim(1);
    else
      ignoreidx = imout(:,:,:,i) >= clim(2);
    end

    Irgb = MakeSVMapUniqueColors(imout(:,:,:,i),maxidx(:,:,i),cm,clim,labels,3,ignoreidx);
    image(xlim,ylim,permute(Irgb,[2,1,3]),'Parent',hax(i));
  else  
    imagesc(xlim,ylim,permute(imout(:,:,:,i),[2,1,3,4]),'Parent',hax(i));
  end
  axis(hax(i),'image');
  text(xtextoff,ylim(2),sprintf('z \\in [%.1f,%.1f]',z0s(i)*umperpx,z1s(i)*umperpx),'Color','w','HorizontalAlignment','left','VerticalAlignment','bottom','Parent',hax(i));
  if ~isempty(dtick),
    set(gca,'XTick',xticks,'YTick',yticks);
  end
  if ~isempty(maskdata),
    hold(hax(i),'on');  
    for j = 1:numel(compartmentslices{i}),
      if isempty(compartmentslices{i}{j}),
        continue;
      end
      for k = 1:numel(compartmentslices{i}{j}),
        plot(hax(i),compartmentslices{i}{j}{k}(:,2)*umperpx,compartmentslices{i}{j}{k}(:,1)*umperpx,'-','Color',compartmentboundarycolor,'LineWidth',.5);
      end
    end
    for k = 1:numel(maxprojslices{i}),
      plot(hax(i),maxprojslices{i}{k}(:,2)*umperpx,maxprojslices{i}{k}(:,1)*umperpx,'-','Color',boundarycolor);
    end

  end
end
for i = 1:nslicesx,
  
  if makeuniquesvcolors,

    if dologcmap,
      ignoreidx = imoutx(:,:,:,i) <= clim(1);
    else
      ignoreidx = imoutx(:,:,:,i) >= clim(2);
    end

    Irgbx = MakeSVMapUniqueColors(imoutx(:,:,:,i),maxidxx(:,:,i),cm,clim,labels,2,ignoreidx);
    imagesc(0,'Parent',hax(i+nslices),clim);
    hold(hax(i+nslices),'on');
    image(xlim,zlim,permute(Irgbx,[2,1,3]),'Parent',hax(i+nslices));
  
  else
    imagesc(xlim,zlim,permute(imoutx(:,:,:,i),[2,1,3,4]),'Parent',hax(i+nslices));
  end
  axis(hax(i+nslices),'image');
  set(hax(i+nslices),'YDir','normal');
  text(xtextoff,ylim(1),sprintf('y \\in [%.1f,%.1f]',x0s(i)*umperpx,x1s(i)*umperpx),'Color',boundarycolor,'HorizontalAlignment','left','VerticalAlignment','bottom','Parent',hax(i+nslices));
  if ~isempty(dtick),
    set(hax(i+nslices),'XTick',xticks,'YTick',zticks);
  end
  if ~isempty(maskdata),
    hold(hax(i+nslices),'on');  
    for j = 1:numel(compartmentslicesx{i}),
      if isempty(compartmentslicesx{i}{j}),
        continue;
      end
      for k = 1:numel(compartmentslicesx{i}{j}),
        plot(hax(i+nslices),compartmentslicesx{i}{j}{k}(:,1)*umperpx,compartmentslicesx{i}{j}{k}(:,2)*umperpx,'-','Color',compartmentboundarycolor,'LineWidth',.5);
      end
    end
    for k = 1:numel(maxprojslicesx{i}),
      plot(hax(i+nslices),maxprojslicesx{i}{k}(:,1)*umperpx,maxprojslicesx{i}{k}(:,2)*umperpx,'-','Color',boundarycolor);
    end

  end
end

set(hax,'CLim',clim);
colormap(cm);
cb = colorbar('Peer',hax(1),'Location','East','XColor',boundarycolor,'YColor',boundarycolor);
if dologcmap,
  set(cb,'YTick',log10(maxpvalue)-log10(fliplr(pvalueslabel)),'YTickLabel',fliplr(pvaluelabels));
end
if ~isempty(figtitle),
  text(xtextoff,xtextoff,figtitle,'Parent',hax(1),'Color',boundarycolor,'HorizontalAlignment','left','VerticalAlignment','top','Interpreter','none');
end
set(hfigs(2),'InvertHardCopy','off');

maxprojslices_out = maxprojslices;
maxprojslicesx_out = maxprojslicesx;

end

%% plot slices

nslicestotal = numel(xslices)+numel(yslices)+numel(zslices);
graycolor = .25;
lw = 1;
if nslicestotal > 0,

  dircolors = [.8,.8,0
    0,.8,.8
    0,0,1];

  
  if numel(hfigs) < 3,
    hfigs(3) = figure;
  elseif ~ishandle(hfigs(3)),
    figure(hfigs(3));
  else
    set(0,'CurrentFigure',hfigs(3));
    clf;
  end
  set(hfigs(3),'Color','w','Units','pixels','Position',[20 20 966 1466],'InvertHardCopy','off');

  sz0 = size(labels);
  
  haxslice = createsubplots(nslicestotal+1,1,.05);
  slicecounter = 1;
  
%   plot3(haxslice(end),[1,sz0(1)],[1,1],[1,1],'k-');
%   hold(haxslice(end),'on');
%   plot3(haxslice(end),[1,1],[1,sz0(2)],[1,1],'k-');
%   plot3(haxslice(end),[1,1],[1,1],[1,sz0(3)],'k-');
  plot3(haxslice(end),umperpx,umperpx,umperpx,'k.');
  hold(haxslice(end),'on');
  axis(haxslice(end),'equal');
  set(haxslice(end),'XLim',xlim,'YLim',ylim,'ZLim',zlim,...
    'XGrid','on','YGrid','on','ZGrid','on','XColor',dircolors(1,:),...
    'YColor',dircolors(2,:),'ZColor',dircolors(3,:));
  if ~isempty(dtick),
    set(haxslice(end),'XTick',xticks,'YTick',yticks,'ZTick',zticks);
  end
  xlabel(haxslice(end),'x');
  ylabel(haxslice(end),'y');
  zlabel(haxslice(end),'z');
  
  xdimperdir = [sz0(3),sz0(1),sz0(1)]*umperpx;
  ydimperdir = [sz0(2),sz0(3),sz0(2)]*umperpx;
  maxxdim = max(xdimperdir);
  maxydim = max(ydimperdir);
  npadx0 = floor(maxxdim/2)-floor(xdimperdir/2);
  npadx1 = maxxdim-npadx0-xdimperdir;
  npady0 = floor(maxydim/2)-floor(ydimperdir/2);
  npady1 = maxydim-npady0-ydimperdir;
%   npadx0 = npadx0*umperpx;
%   npadx1 = npadx1*umperpx;
%   npady0 = npady0*umperpx;
%   npady1 = npady1*umperpx;
    
  for dir = 1:3,
    switch dir,
      case 1,
        slices = xslices;
        coordname = 'x';
        xcoordname = 'z';
        ycoordname = 'y';
      case 2,
        slices = yslices;
        coordname = 'y';
        xcoordname = 'x';
        ycoordname = 'z';
      case 3.
        slices = zslices;
        coordname = 'z';
        xcoordname = 'x';
        ycoordname = 'y';
    end
    
    eval(sprintf('xlimcurr = %slim;',xcoordname));
    eval(sprintf('ylimcurr = %slim;',ycoordname));
    if ~isempty(dtick),
      eval(sprintf('xtickscurr = %sticks;',xcoordname));
      eval(sprintf('ytickscurr = %sticks;',ycoordname));
    end
    
    for slicei = 1:numel(slices),
      switch dir,
        case 1,
          slice = behaviormap(slices(slicei),:,:);
        case 2,
          slice = behaviormap(:,slices(slicei),:);
        case 3,
          slice = behaviormap(:,:,slices(slicei));
      end
      sz = sz0;
      sz(dir) = [];
      slice = reshape(slice,sz);
      
      if dologcmap,
        ignoreidx = slice <= clim(1);
      else
        ignoreidx = slice >= clim(2);
      end
      
      Irgbslice = MakeSVMapUniqueColors(slice,repmat(slices(slicei),sz),cm,clim,labels,dir,ignoreidx);
      % blah! which way is up!
      if ismember(dir,[2,3]),
        Irgbslice = permute(Irgbslice,[2,1,3]);
        xi = 1;
        yi = 2;
      else
        xi = 2;
        yi = 1;
      end
%       Irgbslice = cat(2,graycolor+zeros([size(Irgbslice,1),npadx0(dir),3]),Irgbslice,...
%         graycolor+zeros([size(Irgbslice,1),npadx1(dir),3]));
%       Irgbslice = cat(1,graycolor+zeros([npady0(dir),size(Irgbslice,2),3]),Irgbslice,...
%         graycolor+zeros([npady1(dir),size(Irgbslice,2),3]));
        
      xlimpad = [1-npadx0(dir),xdimperdir(dir)+npadx1(dir)];
      ylimpad = [1-npady0(dir),ydimperdir(dir)+npady1(dir)];
      image(xlimcurr,ylimcurr,Irgbslice,'Parent',haxslice(slicecounter));
      axis(haxslice(slicecounter),'image');
      hold(haxslice(slicecounter),'on');
      [compartmentslicescurr,maxprojslicescurr] = ComputeCompartmentBoundariesPerSlice(maskdata,slices(slicei),slices(slicei),dir,true);
      i = 1;
      for j = 1:numel(compartmentslicescurr{i}),
        if isempty(compartmentslicescurr{i}{j}),
          continue;
        end
        for k = 1:numel(compartmentslicescurr{i}{j}),
          plot(haxslice(slicecounter),compartmentslicescurr{i}{j}{k}(:,xi)*umperpx,compartmentslicescurr{i}{j}{k}(:,yi)*umperpx,'-','Color',compartmentboundarycolor,'LineWidth',.5);
        end
      end
      for k = 1:numel(maxprojslicescurr{i}),
        plot(haxslice(slicecounter),maxprojslicescurr{i}{k}(:,xi)*umperpx,maxprojslicescurr{i}{k}(:,yi)*umperpx,'-','Color',boundarycolor);
      end

      switch xcoordname,
        case 'x',
          slices1 = xslices;
          color1 = dircolors(1,:);
        case 'y',
          slices1 = yslices;
          color1 = dircolors(2,:);
        case 'z',
          slices1 = zslices;
          color1 = dircolors(3,:);
      end
      for slicei1 = 1:numel(slices1),
        plot(haxslice(slicecounter),slices1(slicei1)*umperpx+[0,0],ylimpad,'--','Color',color1);
      end
      switch ycoordname,
        case 'x',
          slices1 = xslices;
          color1 = dircolors(1,:);
        case 'y',
          slices1 = yslices;
          color1 = dircolors(2,:);
        case 'z',
          slices1 = zslices;
          color1 = dircolors(3,:);
      end
      for slicei1 = 1:numel(slices1),
        plot(haxslice(slicecounter),xlimpad,slices1(slicei1)*umperpx+[0,0],'--','Color',color1);
      end
      
      set(haxslice(slicecounter),'XLim',xlimpad,'YLim',ylimpad,'Color',graycolor+[0,0,0],'XColor',dircolors(dir,:),'YColor',dircolors(dir,:));
      if ~isempty(dtick),
        set(haxslice(slicecounter),'XTick',xtickscurr,'YTick',ytickscurr);
      end
      if ~strcmp(ycoordname,'y'),
        set(haxslice(slicecounter),'YDir','normal');
        ytext = ylimpad(1);
      else
        ytext = ylimpad(2);
      end
      text(xlimpad(1)+xtextoff,ytext,sprintf('%s = %.1f',coordname,slices(slicei)*umperpx),'Color',boundarycolor,'HorizontalAlignment','left','VerticalAlignment','bottom','Parent',haxslice(slicecounter),'Interpreter','none');
      xlabel(haxslice(slicecounter),xcoordname);
      ylabel(haxslice(slicecounter),ycoordname);
      
      slicecounter = slicecounter + 1;

      switch dir,
        case 1,
          patch(repmat(slices(slicei)*umperpx,[1,5]),[1,1,sz0(2),sz0(2),1]*umperpx,[1,sz0(3),sz0(3),1,1]*umperpx,dircolors(dir,:),'Parent',haxslice(end),...
            'FaceAlpha',.25,'EdgeColor','none');
          plot3(haxslice(end),slices(slicei)*umperpx+[0,0],[1,sz0(2)]*umperpx,[1,1]*umperpx,'-','Color',dircolors(dir,:),'LineWidth',lw);
          plot3(haxslice(end),slices(slicei)*umperpx+[0,0],[sz0(2),sz0(2)]*umperpx,[1,sz0(3)]*umperpx,'-','Color',dircolors(dir,:),'LineWidth',lw);
          for k = 1:numel(maxprojslicescurr{i}),
            plot3(haxslice(end),repmat(slices(slicei)*umperpx,size(maxprojslicescurr{i}{k}(:,1))),maxprojslicescurr{i}{k}(:,1)*umperpx,maxprojslicescurr{i}{k}(:,2)*umperpx,'-','Color',dircolors(dir,:),'LineWidth',lw);
          end
        case 2,
          patch([1,1,sz0(1),sz0(1),1]*umperpx,repmat(slices(slicei)*umperpx,[1,5]),[1,sz0(3),sz0(3),1,1]*umperpx,dircolors(dir,:),'Parent',haxslice(end),...
            'FaceAlpha',.25,'EdgeColor','none');
          plot3(haxslice(end),[1,sz0(1)]*umperpx,slices(slicei)*umperpx+[0,0],[1,1]*umperpx,'-','Color',dircolors(dir,:),'LineWidth',lw);
          plot3(haxslice(end),[1,1]*umperpx,slices(slicei)*umperpx+[0,0],[1,sz0(3)]*umperpx,'-','Color',dircolors(dir,:),'LineWidth',lw);
          for k = 1:numel(maxprojslicescurr{i}),
            plot3(haxslice(end),maxprojslicescurr{i}{k}(:,1)*umperpx,repmat(slices(slicei)*umperpx,size(maxprojslicescurr{i}{k}(:,1))),maxprojslicescurr{i}{k}(:,2)*umperpx,'-','Color',dircolors(dir,:),'LineWidth',lw);
          end
        case 3,
          patch([1,1,sz0(1),sz0(1),1]*umperpx,[1,sz0(2),sz0(2),1,1]*umperpx,repmat(slices(slicei)*umperpx,[1,5]),dircolors(dir,:),'Parent',haxslice(end),...
            'FaceAlpha',.25,'EdgeColor','none');
          plot3(haxslice(end),[1,sz0(1)]*umperpx,[sz0(2),sz0(2)]*umperpx,slices(slicei)*umperpx+[0,0],'-','Color',dircolors(dir,:),'LineWidth',lw);
          plot3(haxslice(end),[1,1]*umperpx,[1,sz0(2)]*umperpx,slices(slicei)*umperpx+[0,0],'-','Color',dircolors(dir,:),'LineWidth',lw);
          for k = 1:numel(maxprojslicescurr{i}),
            plot3(haxslice(end),maxprojslicescurr{i}{k}(:,1)*umperpx,maxprojslicescurr{i}{k}(:,2)*umperpx,repmat(slices(slicei)*umperpx,size(maxprojslicescurr{i}{k}(:,1))),'-','Color',dircolors(dir,:),'LineWidth',lw);
          end
      end
      
    end
  end
  %set(haxslice(end),'CameraPosition',[-500,-3742,2019]);
  set(haxslice(end),'YDir','reverse');

end
