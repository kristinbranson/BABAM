function [filenamecurr] = MakeLineInfoWebpageNoMetadata(line_names,varargin)

timestamp = datestr(now,'yyyymmddTHHMMSS');
persistent imdata;
persistent imdata_vnc;

[imdata,imdata_vnc,...
  groupname,filenamecurr] = myparse(varargin,...
  'imdata',imdata,...
  'imdata_vnc',imdata_vnc,...
  'groupname',sprintf('Group selected %s',timestamp),...
  'outfilename','');

if isempty(imdata) || isempty(imdata_vnc),
  [f,p] = uigetfile('*.mat','Select imdata mat file','/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/ImageryData20150901.mat');
  if ~ischar(f),
    return;
  end
  imagerydatafile = fullfile(p,f);
  imdata = load(imagerydatafile,'imdata','imdata_vnc');
  imdata = imdata.imdata;
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
  
  for i = 1:nlines,
    fprintf(fid,'<h1>%s</h1>\n',line_names{i});
    
    reg_file = '';
    idxanat = find(strcmp({imdata.line},line_names{i}));
    [~,order] = sort([imdata(idxanat).qi]);
    for j = idxanat(order)',
      maxproj_file = imdata(j).maxproj_file_system_path;
      reg_file = regexprep(maxproj_file,'_total.jpg$','.reg.local.jpg');
      if exist(reg_file,'file'),
        break;
      else
        reg_file = '';
      end
    end
    
    if ~isempty(reg_file) && exist(reg_file,'file'),
      fprintf(fid,'<a href="%s"><img src="%s" height="200"></a></p>\n',reg_file,reg_file);
    end
    
    idxanat = find(strcmp({imdata.line},line_names{i}));
    if isempty(idxanat),
      fprintf(fid,'<p>No images found.</p>\n');
    else
      fprintf(fid,'<ul>\n');
      for j = idxanat(:)',
        name = imdata(j).name;
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
      fprintf(fid,'</ul>\n');
    end
    
    idxanat = find(strcmp({imdata_vnc.line},line_names{i}));
    if isempty(idxanat),
      fprintf(fid,'<p>No VNC images found.</p>\n');
    else
      fprintf(fid,'<ul>\n');
      for j = idxanat(:)',
        name = imdata_vnc(j).name;
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
