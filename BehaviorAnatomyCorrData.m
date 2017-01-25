classdef BehaviorAnatomyCorrData < matlab.mixin.Copyable

  % -----------------------------------------------------------------------
  properties (Access=public)
    % file containing per-line info
    datafilename = '/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/ComputeBehaviorAnatomyMap_NormBehaviorData_20150825.mat';

    % where the average anatomy mat files are stored
    anatomydir = '/groups/branson/bransonlab/projects/olympiad/AverageAnatomyData20141028';
    
    % supervoxel clustering
    supervoxelfilename = '/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/ComputeBehaviorAnatomyMapData_ms_centers0.750000_w0.000010_r2_20150202.mat';
  
    % location of flylight data
    flylightdir = '';    
    defaultflylightdir = '/tier2/flylight/screen';
    
    % location of behavior data
    %behaviordir = '';
    %defaultbehaviordir = '/groups/sciserv/flyolympiad/Olympiad_Screen/fly_bowl/bowl_data';
    linebehaviordir = 'http://research.janelia.org/bransonlab/FlyBowl/BehaviorResults';
    defaultlinebehaviordir = 'http://research.janelia.org/bransonlab/FlyBowl/BehaviorResults';
    
    % whether user has access to Fly Light Secure data
    superuser = 0;
    
    % per-line info
    nbdata = [];
  
    % current behavior-anatomy map data
    bamap = [];
    
    % supervoxel clustering info
    labeldata = [];
    
    compute_map_usecluster = false;
    compute_map_nsamplestotal = 1000;
    compute_map_nsamplesperbatch = 1000;
    compute_map_fdr_alpha = .25;
    
    SetStatusFcn = @(varargin) fprintf([varargin{1},'\n'],varargin{2:end});
    ClearStatusFcn = @(varargin) fprintf('Done\n');
    
  end
  
  % ----------------------------------------------------
  methods
    
    function obj = BehaviorAnatomyCorrData(varargin)
      
      for i = 1:2:numel(varargin)-1,
        if isprop(obj,varargin{i}),
          obj.(varargin{i}) = varargin{i+1};
        else
          warning('Unknown property %s, skipping');
        end
      end
      
    end
    
    function LoadNBData(obj)
      
      required_fns = {'behaviorlabels','normbehaviordata_plus','normbehaviordata_minus','line_names_curr','imdata','imdata_vnc'};
      desired_fns = {'metadata','pvaluedata'};
      fns = who('-file',obj.datafilename);
      missing_fns = setdiff(required_fns,fns);
      if ~isempty(missing_fns),
        error('%s missing the follow fields: %s',obj.datafilename,sprintf('%s ',missing_fns{:}));
      end
      fns = intersect(fns,[required_fns,desired_fns]);
      
      obj.nbdata = load(obj.datafilename,fns{:});
      obj.SetFlyLightDir(obj.defaultflylightdir);
      %obj.SetBehaviorDir(obj.defaultbehaviordir);
      
    end
    
    function SetFlyLightDir(obj,oldflylightdir)
      nold = numel(oldflylightdir);
      if ~isempty(obj.flylightdir) && exist(obj.flylightdir,'dir'),
        fnsfix = {'maxproj_file_system_path','translation_file_path','path'};
        for i = 1:numel(fnsfix),
          fn = fnsfix{i};
          for j = 1:numel(obj.nbdata.imdata),
            if numel(obj.nbdata.imdata(j).(fn)) >= nold && strcmp(oldflylightdir,obj.nbdata.imdata(j).(fn)(1:nold)),
              obj.nbdata.imdata(j).(fn) = fullfile(obj.flylightdir,obj.nbdata.imdata(j).(fn)(nold+2:end));
            end
            %obj.nbdata.imdata(j).(fn) = regexprep(obj.nbdata.imdata(j).(fn),['^',oldflylightdir],obj.flylightdir);
          end
          for j = 1:numel(obj.nbdata.imdata_vnc),
            if numel(obj.nbdata.imdata_vnc(j).(fn)) >= nold && strcmp(oldflylightdir,obj.nbdata.imdata_vnc(j).(fn)(1:nold)),
              obj.nbdata.imdata_vnc(j).(fn) = fullfile(obj.flylightdir,obj.nbdata.imdata_vnc(j).(fn)(nold+2:end));
            end
            %obj.nbdata.imdata_vnc(j).(fn) = regexprep(obj.nbdata.imdata_vnc(j).(fn),['^',oldflylightdir],obj.flylightdir);
          end
        end
        obj.superuser = true;
      else
        obj.superuser = false;
      end
      
    end
    
%     function SetBehaviorDir(obj,oldbehaviordir)
%       if ~isempty(obj.behaviordir) && exist(obj.behaviordir,'dir'),
%         fnsfix = {'file_system_path'};
%         nold = numel(oldbehaviordir);
%         for i = 1:numel(fnsfix),
%           fn = fnsfix{i};
%           for j = 1:numel(obj.nbdata.metadata),
%             if numel(obj.nbdata.metadata(j).(fn)) >= nold && strcmp(oldbehaviordir,obj.nbdata.metadata(j).(fn)(1:nold)),
%               obj.nbdata.metadata(j).(fn) = fullfile(obj.behaviordir,obj.nbdata.metadata(j).(fn)(nold+2:end));
%             end
%             %obj.nbdata.metadata(j).(fn) = regexprep(obj.nbdata.metadata(j).(fn),['^',oldbehaviordir],obj.behaviordir);
%           end
%         end
%       end      
%     end
        
    function ComputeBAMap(obj,behaviorstring,varargin)
      
      obj.bamap = ComputeBehaviorAnatomyMap_Logic(behaviorstring,obj.nbdata.normbehaviordata_plus,...
        obj.nbdata.normbehaviordata_minus,obj.nbdata.behaviorlabels,'doplot',false,...
        'matfile',obj.supervoxelfilename,...
        'usecluster',obj.compute_map_usecluster,...
        'nsamplestotal',obj.compute_map_nsamplestotal,...
        'nsamplesperbatch',obj.compute_map_nsamplesperbatch,...
        'fdr_alpha',obj.compute_map_fdr_alpha,...
        varargin{:});
      
      if isempty(obj.labeldata),
        obj.SetStatusFcn('Loading anatomy data...');
        obj.labeldata = load(obj.bamap.matfile,'labels','maskdata','coloring');
        obj.labeldata.labels = permute(obj.labeldata.labels,[2,1,3]);
        obj.ClearStatusFcn();
      end

    end
    
  end
end