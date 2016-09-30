function   [pvalue,nsmaller] = ComputeBehaviorAnatomyCorrPValues_asymm(normbehaviordata,...
  supervoxeldata,baindex,...
  nsamplestotal,varargin)

NCORESPERJOB = 1;
TMP_ROOT_DIR = '/scratch';
MCR = '/groups/branson/bransonlab/share/MCR/v717';
SCRIPT = '/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/ComputePValueBehaviorAnatomySupervoxel_asymm/distrib/run_ComputePValueBehaviorAnatomySupervoxel_asymm.sh';

[usecluster,nsamplesperbatch,tmpdir,timestamp,doclean] = myparse(varargin,'usecluster',[],'nsamplesperbatch',500,...
  'tmpdir','','timestamp',datestr(now,'yyyymmdd'),'doclean',false);

if isempty(usecluster),
  if ~isunix,
    usecluster = false;
  else
    [tmp1,tmp2] = unix('which ssh');
    if tmp1 ~= 0 || isempty(tmp2),
      usecluster = false;
    else
      usecluster = exist(SCRIPT,'file') && nsamplestotal >= nsamplesperbatch*2;
    end
  end
end

supervoxeldata_t = supervoxeldata';
dosavesamples = false; 

if usecluster,
  [~, username] = unix('whoami');
  username = strtrim(username);
  TMP_ROOT_DIR = fullfile(TMP_ROOT_DIR,username);
  MCR_CACHE_ROOT = fullfile(TMP_ROOT_DIR,'mcr_cache_root');
  curdir = pwd;
  if isempty(tmpdir),
    tmpdir = fullfile(curdir,sprintf('pv%s',timestamp));
  end
  if ~exist(tmpdir,'dir'),
    mkdir(tmpdir);
  end
  tmpdatafile = fullfile(tmpdir,sprintf('ComputePValueBehaviorAnatomySupervoxelData%s.mat',timestamp));
  nsamples = nsamplesperbatch; %#ok<NASGU>
  save(tmpdatafile,'normbehaviordata',...
    'supervoxeldata_t',...
    'baindex',...
    'nsamples','dosavesamples');
  
  % start running on cluster
  
  nbatches = ceil(nsamplestotal/nsamplesperbatch);
  jobids = [];
  outfiles = cell(1,nbatches);
  for batchi = 1:nbatches,
    jobid = sprintf('pv%s_%03d',timestamp,batchi);
    outfiles{batchi} = fullfile(tmpdir,['log_',jobid,'.txt']);
    scriptfile = fullfile(tmpdir,[jobid,'.sh']);
    fid = fopen(scriptfile,'w');
    fprintf(fid,'if [ -d %s ]\n',TMP_ROOT_DIR);
    fprintf(fid,'  then export MCR_CACHE_ROOT=%s.%s\n',MCR_CACHE_ROOT,jobid);
    fprintf(fid,'fi\n');
    fprintf(fid,'%s %s %s %05d\n',...
      SCRIPT,MCR,tmpdatafile,batchi);
    fclose(fid);
    unix(sprintf('chmod u+x %s',scriptfile));
    cmd = sprintf('ssh login1 ''source /etc/profile; cd "%s"; qsub -pe batch %d -N %s -j y -b y -l short=true -o ''%s'' -cwd ''\"%s\"''''',...
      curdir,NCORESPERJOB,jobid,outfiles{batchi},scriptfile);
    [tmp1,tmp2] = unix(cmd);
    if tmp1 ~= 0,
      error('Error submitting job %d:\n%s ->\n%s\n',batchi,cmd,tmp2);
    end
    m = regexp(tmp2,'job (\d+) ','once','tokens');
    jobids = [jobids,str2double(m)]; %#ok<AGROW>
  end

  nerrors = 0;
  while true,
    % check how many jobs are done
    [p,n,~] = fileparts(tmpdatafile);
    savefiles = dir(fullfile(p,sprintf('%s_samples*_*.mat',n)));
    batchis = regexp({savefiles.name},'_(\d+)\.mat','tokens','once');
    batchis = str2double([batchis{:}]);
    batchis = batchis(batchis<=nbatches);
    batchis = sort(batchis);
    doremove = false(1,numel(batchis));
    for j = unique(batchis),
      idx = find(batchis == j);
      if numel(idx) > 1,
        [~,k] = max([savefiles(idx).datenum]);
        doremove(idx([1:k-1,k+1:numel(idx)])) = true;
      end
    end
    savefiles(doremove) = [];
    batchis(doremove) = [];
    fprintf('%d / %d batches done\n',numel(batchis),nbatches);
    if numel(batchis) == nbatches,
      break;
    else
      
      batchisleft = setdiff(1:nbatches,batchis);
      fprintf('Batches %s not done.\n',mat2str(batchisleft));
      batchi = batchisleft(1);
      outfile = outfiles{batchi};
      if exist(outfile,'file'),
        fprintf('End of log file for batch %d:\n',batchi);
        unix(sprintf('tail -n 20 %s',outfile));
      else
        fprintf('Log file for batch %d does not exist (yet).\n',batchi);
      end
      
      cmd = ['ssh login1 ''source /etc/profile; qstat -j',sprintf(' %d',jobids(batchisleft)),''''];
      [tmp1,~] = unix(cmd);
      if tmp1 > 0,
        nerrors = nerrors+1;
        if nerrors > 5,
          warning('At least one job is currently not running for which an output file has not been found. This has happened %d times in a row. Quitting.',nerrors);
          keyboard;
        else
          warning('At least one job is currently not running for which an output file has not been found. This has happened %d times in a row.',nerrors);
        end        
      else
        nerrors = 0;
      end
    end
    pause(30);
  end
  
  % load in the results
  nsmaller = 0;
  nsamplescurr = 0;
  for i = 1:numel(batchis),
    
    savefile = fullfile(p,savefiles(i).name);
    d = load(savefile,'nsmaller','nsamples0');
    nsmaller = nsmaller + d.nsmaller;
    nsamplescurr = nsamplescurr + d.nsamples0;
    if doclean,
      delete(savefile);
    end
    
  end
  
  pvalue = 1 - nsmaller/nsamplescurr;

  if doclean,
    delete(tmpdatafile);
  end
  
else
    
  [pvalue,nsmaller] = ...
    ComputePValueBehaviorAnatomySupervoxel_asymm(normbehaviordata,supervoxeldata_t,baindex,nsamplestotal,dosavesamples);
  
end

