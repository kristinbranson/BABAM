function [filenamecurr] = MakeLineInfoWebpage(line_names,varargin)

persistent metadata;
lineresultsdir_file = '/groups/branson/bransonlab/projects/olympiad/FlyBowlResults';
lineresultsdir_web = 'http://research.janelia.org/bransonlab/FlyBowl/BehaviorResults';
timestamp = datestr(now,'yyyymmddTHHMMSS');
persistent imdata;
persistent imdata_vnc;

[metadata,imdata,imdata_vnc,lineresultsdir,...
  groupname,filenamecurr,perlinetext,...
  isflylightdir,usewebctraxvideo,usewebbehaviorfiles,anatomyurlprefix] = myparse(varargin,...
  'metadata',metadata,...
  'imdata',imdata,...
  'imdata_vnc',imdata_vnc,...
  'lineresultsdir','',...
  'groupname',sprintf('Group selected %s',timestamp),...
  'outfilename','',...
  'perlinetext',{},...
  'isflylightdir',true,...
  'usewebctraxvideo',true,...
  'usewebbehaviorfiles',true,...
  'anatomyurlprefix','http://flweb.janelia.org/cgi-bin/view_flew_imagery.cgi?line=');

if isempty(lineresultsdir),
  if usewebbehaviorfiles,
    lineresultsdir = lineresultsdir_web;
  else
    lineresultsdir = lineresultsdir_file;
  end
else
  usewebbehaviorfiles = numel(lineresultsdir) > 4 && strcmp(lineresultsdir(1:4),'http');
end

if isempty(metadata),
  [f,p] = uigetfile('*.mat','Select metadata mat file','/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/CollectedPrimaryMetadata20140224.mat');
  if ~ischar(f),
    return;
  end
  metadatafile = fullfile(p,f);
  metadata = load(metadatafile,'metadata');
  metadata = metadata.metadata;
end
if isflylightdir && (isempty(imdata) || isempty(imdata_vnc)),
  [f,p] = uigetfile('*.mat','Select imdata mat file','/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/ImageryData20150901.mat');
  if ~ischar(f),
    return;
  end
  imagerydatafile = fullfile(p,f);
  imdata = load(imagerydatafile,'imdata','imdata_vnc');
  imdata = imdata.imdata;
end  

isflylightwebsiteinfo = isfield(imdata,'maxproj_url');
if isflylightwebsiteinfo,
  isonweb = ~cellfun(@isempty,{imdata.maxproj_url});
  isonweb_vnc = ~cellfun(@isempty,{imdata_vnc.maxproj_url});
end
ctraxvideoisonweb = isfield(metadata,'youtube_url');
if ~ctraxvideoisonweb,
  usewebctraxvideo = false;
end

nlines = numel(line_names);

% create an html page with links to all experiments
if isempty(filenamecurr),
  filenamecurr = fullfile(tempdir,sprintf('selectedgroup_%s.html',timestamp));
end
fid = fopen(filenamecurr,'w');
if fid < 1,
  warning('Could not open temporary file %s for writing.',filenamecurr);
  filenamecurr = '';
  return;
else
    
  fprintf(fid,'<html>\n<title>%s</title>\n<body>\n',groupname);
  fprintf(fid,'<head>\n');
  fprintf(fid,'<style>\n');
  fprintf(fid,'table\n');
  fprintf(fid,'{\n');
  fprintf(fid,'border-collapse:collapse;\n');
  fprintf(fid,'}\n');
  fprintf(fid,'table, td, th\n');
  fprintf(fid,'{\n');
  fprintf(fid,'border:1px solid black;\n');
  fprintf(fid,'}\n');
  fprintf(fid,'</style>\n');
  fprintf(fid,'</head>\n');
  
  fprintf(fid,'<center><h1>%s</h1></center>\n',groupname);
  
  for i = 1:nlines,
    % this could be a url, so don't use \ on pc
    lineresultsdircurr = [lineresultsdir,'/',line_names{i}];
    fprintf(fid,'<a href="%s/index.html"><h1>%s</h1></a>\n',lineresultsdircurr,line_names{i});
    
    if numel(perlinetext) >= i && ~isempty(perlinetext{i}),
      fprintf(fid,'<p>%s</p>\n',perlinetext{i});
    end
    
    reg_file = '';
    if ~isflylightdir && isflylightwebsiteinfo,
      idxanat = find(isonweb&strcmp({imdata.line},line_names{i}));
    else
      idxanat = find(strcmp({imdata.line},line_names{i}));
    end
    [~,order] = sort([imdata(idxanat).qi]);
    for j = idxanat(order)',
      if ~isflylightdir && isflylightwebsiteinfo,
        reg_file = imdata(j).reg_file_url;
        if ~isempty(reg_file),
          break;
        end
      else
        maxproj_file = imdata(j).maxproj_file_system_path;
        reg_file = regexprep(maxproj_file,'_total.jpg$','.reg.local.jpg');
        if exist(reg_file,'file'),
          break;
        else
          reg_file = '';
        end
      end
    end
    
    lineresultsimfile = [lineresultsdircurr,'/analysis_plots/stats_basic.png'];
    fprintf(fid,'<p><a href="%s"><img src="%s" height="500"></a>\n',lineresultsimfile,lineresultsimfile);
    if ~isempty(reg_file),
      fprintf(fid,'<a href="%s"><img src="%s" height="200"></a></p>\n',reg_file,reg_file);
    end
    fprintf(fid,'<p><a href="%s/index.html">Line behavior results</a></p>\n',lineresultsdircurr);

    shortlinename = regexprep(line_names{i},'^GMR_','R');
    shortlinename = regexprep(shortlinename,'_A._01$','');
    fprintf(fid,'<p><a href="%s%s">Fly Light imagery</a></p>\n',anatomyurlprefix,shortlinename);

    
    idx = find(strcmp({metadata.line_name},line_names{i}));
    if isempty(idx),
      fprintf(fid,'<p>No experiments found.</p>\n');
    else
      fprintf(fid,'<ul>\n');
      for j = idx(:)',
        [~,name] = fileparts(metadata(j).file_system_path);
        moviename = fullfile(metadata(j).file_system_path,...
          sprintf('ctrax_results_movie_%s.avi',name));
        if ~exist(moviename,'file'),
          moviename = '';
        else
          moviename = ['file://',moviename]; %#ok<AGROW>
        end
        if (isempty(moviename) || usewebctraxvideo) && ~isempty(metadata(j).youtube_url),
          moviename = metadata(j).youtube_url;
        end
        [~,n] = fileparts(metadata(j).file_system_path);
        plotsname = [lineresultsdircurr,'/',n,'/analysis_plots'];
        if ~usewebbehaviorfiles,
          plotsname = ['file://',plotsname];
        else
          plotsname = [plotsname,'/index.html'];
        end
        fprintf(fid,'  <li>%s: ',name);
        fprintf(fid,'<a href="%s">Ctrax results movie</a>',moviename);
        fprintf(fid,', ');
        fprintf(fid,'<a href="%s">Analysis plots</a>',plotsname);
        fprintf(fid,'</li>\n');
        
      end
      fprintf(fid,'</ul>\n');
    end
    
    if ~isflylightdir && isflylightwebsiteinfo,
      idxanat = find(isonweb&strcmp({imdata.line},line_names{i}));
    else
      idxanat = find(strcmp({imdata.line},line_names{i}));
    end
    if isempty(idxanat),
      fprintf(fid,'<p>No images found.</p>\n');
    else
      fprintf(fid,'<ul>\n');
      for j = idxanat(:)',
        name = imdata(j).name;
        if ~isflylightdir && isflylightwebsiteinfo,
          maxproj_file = imdata(j).maxproj_url;
          maxproj_ch2_file = imdata(j).maxproj_ch2_url;
          reg_file = imdata(j).reg_file_url;
          translation_file = imdata(j).translation_url;
          
          fprintf(fid,'  <li>%s: ',name);
          fprintf(fid,'<a href="%s">Max projection image</a>',maxproj_file);
          fprintf(fid,', <a href="%s">Max proj, channel 2</a>',maxproj_ch2_file);
          fprintf(fid,', <a href="%s">Registered image</a>',reg_file);
          fprintf(fid,', <a href="%s">Translation video</a>',translation_file);
          fprintf(fid,'</li>\n');
          
        else
          maxproj_file = imdata(j).maxproj_file_system_path;
          maxproj_ch2_file = regexprep(maxproj_file,'_total.jpg$','_ch2_total.jpg');
          reg_file = regexprep(maxproj_file,'_total.jpg$','.reg.local.jpg');
          translation_file = imdata(j).translation_file_path;
          if ~exist(maxproj_file,'file') && ~exist(translation_file,'file'),
            continue;
          end
          fprintf(fid,'  <li>%s: ',name);
          if exist(maxproj_file,'file'),
            fprintf(fid,'<a href="file://%s">Max projection image</a>',maxproj_file);
          end
          if exist(maxproj_ch2_file,'file') && ~strcmp(maxproj_file,maxproj_ch2_file),
            fprintf(fid,', <a href="file://%s">Max proj, channel 2</a>',maxproj_ch2_file);
          end
          if exist(reg_file,'file') && ~strcmp(maxproj_file,reg_file),
            fprintf(fid,', <a href="file://%s">Registered image</a>',reg_file);
          end
          if exist(translation_file,'file'),
            fprintf(fid,', <a href="file://%s">Translation video</a>',translation_file);
          end
          fprintf(fid,'</li>\n');
        end
        
      end
      fprintf(fid,'</ul>\n');
    end
    

    if ~isflylightdir && isflylightwebsiteinfo,
      idxanat = find(isonweb_vnc&strcmp({imdata_vnc.line},line_names{i}));
    else
      idxanat = find(strcmp({imdata_vnc.line},line_names{i}));
    end
    if isempty(idxanat),
      fprintf(fid,'<p>No VNC images found.</p>\n');
    else
      fprintf(fid,'<ul>\n');
      for j = idxanat(:)',
        name = imdata_vnc(j).name;
        
        if ~isflylightdir && isflylightwebsiteinfo,
          maxproj_file = imdata_vnc(j).maxproj_url;
          maxproj_ch2_file = imdata_vnc(j).maxproj_ch2_url;
          translation_file = imdata_vnc(j).translation_url;

          fprintf(fid,'  <li>%s: ',name);
          fprintf(fid,'<a href="%s">VNC max projection image</a>',maxproj_file);
          fprintf(fid,', <a href="%s">VNC max proj, channel 2</a>',maxproj_ch2_file);
          fprintf(fid,', <a href="%s">VNC translation video</a>',translation_file);
          fprintf(fid,'</li>\n');

        else
        
          maxproj_file = imdata_vnc(j).maxproj_file_system_path;
          maxproj_ch2_file = regexprep(maxproj_file,'_total.jpg$','_ch2_total.jpg');
          translation_file = imdata_vnc(j).translation_file_path;
          if ~exist(maxproj_file,'file') && ~exist(translation_file,'file'),
            continue;
          end
          fprintf(fid,'  <li>%s: ',name);
          if exist(maxproj_file,'file'),
            fprintf(fid,'<a href="file://%s">VNC max projection image</a>',maxproj_file);
          end
          if exist(maxproj_ch2_file,'file') && ~strcmp(maxproj_file,maxproj_ch2_file),
            fprintf(fid,', <a href="file://%s">VNC max proj, channel 2</a>',maxproj_ch2_file);
          end
          if exist(translation_file,'file'),
            fprintf(fid,', <a href="file://%s">VNC translation video</a>',translation_file);
          end
          fprintf(fid,'</li>\n');
        end
      end
      fprintf(fid,'</ul>\n');
    end
    
  end

  fprintf(fid,'</body>\n</html>\n');
  fclose(fid);
  if ~exist(filenamecurr,'file'),
    warning('Could not open temporary file %s',filenamecurr);
    return;
  else
    % open this page
    web(filenamecurr,'-browser');
  end
end
