function varargout = ExploreBehaviorAnatomyCorrelations(varargin)
% EXPLOREBEHAVIORANATOMYCORRELATIONS MATLAB code for ExploreBehaviorAnatomyCorrelations.fig
%      EXPLOREBEHAVIORANATOMYCORRELATIONS, by itself, creates a new EXPLOREBEHAVIORANATOMYCORRELATIONS or raises the existing
%      singleton*.
%
%      H = EXPLOREBEHAVIORANATOMYCORRELATIONS returns the handle to a new EXPLOREBEHAVIORANATOMYCORRELATIONS or the handle to
%      the existing singleton*.
%
%      EXPLOREBEHAVIORANATOMYCORRELATIONS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EXPLOREBEHAVIORANATOMYCORRELATIONS.M with the given input arguments.
%
%      EXPLOREBEHAVIORANATOMYCORRELATIONS('Property','Value',...) creates a new EXPLOREBEHAVIORANATOMYCORRELATIONS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ExploreBehaviorAnatomyCorrelations_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ExploreBehaviorAnatomyCorrelations_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ExploreBehaviorAnatomyCorrelations

% Last Modified by GUIDE v2.5 12-May-2016 13:31:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ExploreBehaviorAnatomyCorrelations_OpeningFcn, ...
                   'gui_OutputFcn',  @ExploreBehaviorAnatomyCorrelations_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1}) && exist(varargin{1}),
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ExploreBehaviorAnatomyCorrelations is made visible.
function ExploreBehaviorAnatomyCorrelations_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ExploreBehaviorAnatomyCorrelations (see VARARGIN)

% superuser: 1 if we have access to Fly Light secure data, 0 otherwise

% Choose default command line output for ExploreBehaviorAnatomyCorrelations
handles.output = hObject;

handles = DisableInteraction(handles);

handles = InitializeParameters(handles,varargin{:});
handles = InitializeState(handles);
if ~ishandle(handles.figure1),
  return;
end
handles = InitializeGUI(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ExploreBehaviorAnatomyCorrelations wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function handles = InitializeParameters(handles,varargin)

[handles.isanatomydir,leftovers] = myparse_nocheck(varargin,'isanatomydir',[]);

if ischar(handles.isanatomydir),
  handles.isanatomydir = str2double(handles.isanatomydir);
end
handles.dologcmap = true;
handles.minpvalue_log = .0001;
handles.maxpvalue = .051;
handles.minpvalue = handles.minpvalue_log;

handles.pvalueslabel = [.0001,.001,.01,.05,.1,.25];
handles.pvaluelabels = {'.0001','.001','.01','.05','.1','.25'};

% threshold on ba explained for selecting lines
handles.thresh_ba_explained = .75;
% how many negative behavior lines to show
handles.nlinesshow_anotb = 11;
handles.min_anotb_a = .25;
handles.max_anotb_b = .25;
handles.maxnlinesshow = 11;

handles.cluster_k = 10;
handles.clusterres = struct;
handles.cluster_pvalthresh = .01;
handles.cluster_behthresh = .5;
handles.cluster_anatthresh = .5;

handles.nslices = 3;

global EBAC_DATA;

EBAC_DATA = BehaviorAnatomyCorrData('SetStatusFcn',@(varargin) SetStatusCallback(handles.figure1,varargin{:}),...
  'ClearStatusFcn',@(varargin) ClearStatusCallback(handles.figure1,varargin{:}),leftovers{:});

if isunix,
  handles.rcfile = getenv('HOME');
  handles.rcfile = fullfile(handles.rcfile,'.BABAM_rc.mat');
else
  handles.rcfile = '.BABAM_rc.mat';
end

handles.fns_h_rc = {'dologcmap','minpvalue_log','maxpvalue',...
  'minpvalue','pvalueslabel','pvaluelabels',...
  'thresh_ba_explained','nlinesshow_anotb',...
  'min_anotb_a','max_anotb_b','maxnlinesshow',...
  'cluster_k','cluster_pvalthresh','cluster_behthresh','cluster_anatthresh'};
handles.fns_ef_rc = {'datafilename','anatomydir','supervoxelfilename','flylightdir'};
handles.fns_e_rc = {'compute_map_usecluster','compute_map_nsamplestotal','compute_map_nsamplesperbatch','compute_map_fdr_alpha'};

handles.uicontrols_in_pixels = {
  'figure1'
  'text_showsupervoxelclustering'
  'pushbutton_stop_showsupervoxelclustering'
  'uipanel_statusbar'
  'uipanel_cluster'
  'pushbutton_stop_map_expr_corr'
  'text_map_expr_corr'
  'uipanel_supervoxel'
  'uipanel_behavior'
  'edit_z'
  'slider_z'
  'axes_main'
  };

infns = varargin(1:2:end);

if exist(handles.rcfile,'file'),  
  rcdata = load(handles.rcfile);
  
  for i = 1:numel(handles.fns_h_rc),
    fn = handles.fns_h_rc{i};
    if isfield(rcdata,fn),
      handles.(fn) = rcdata.(fn);
    end
  end
  for i = 1:numel(handles.fns_ef_rc),
    fn = handles.fns_ef_rc{i};
    if ~ismember(fn,infns) && isfield(rcdata,fn) && exist(rcdata.(fn),'file'),
      EBAC_DATA.(fn) = rcdata.(fn);
    end
  end
  for i = 1:numel(handles.fns_e_rc),
    fn = handles.fns_e_rc{i};
    if ~ismember(fn,infns) && isfield(rcdata,fn),
      EBAC_DATA.(fn) = rcdata.(fn);
    end
  end
  
  if isfield(rcdata,'figpos'),
    handles.rcfigpos = rcdata.figpos;
  end
  
end

function handles = InitializeState(handles)

global EBAC_DATA;

handles.viewmode = 'maxzprojection';
handles.datatype = 'pvalue';
handles.behaviorstring = '';
handles.behavior1 = '';
handles.behavior2 = '';
handles.logic = '(None)';
handles.more1 = 'plus';
handles.more2 = 'plus';
handles.zslice = 1;
handles.yslice = 1;
handles.masktype = '';
handles.svmasktype = '';
handles.svmaskid = nan;
handles.isadvancedlogic = false;

hObject = handles.figure1;

% initialize all file locations
if ~exist(EBAC_DATA.datafilename,'file'),
  fprintf('Select mat file containing normalized behavior data. Example: BehaviorData.mat...\n');
  if ismac,
    hinfo = helpdlg('Select mat file containing normalized behavior data. Example: BehaviorData.mat','Select data file');
  end
  [n,p] = uigetfile('*.mat','Select mat file containing normalized behavior data');
  if ismac && ishandle(hinfo),
    delete(hinfo);
  end
  if ~ischar(n),
    delete(hObject);
    return;
  end
  EBAC_DATA.datafilename = fullfile(p,n);
end

if ~exist(EBAC_DATA.supervoxelfilename,'file'),
  fprintf('Select supervoxel clustering data mat file. Example: SupervoxelClusteringData.mat...\n');
  if ismac,
    hinfo = helpdlg('Select supervoxel clustering data mat file. Example: SupervoxelClusteringData.mat','Select data file');
  end
  [n,p] = uigetfile('*.mat','Supervoxel clustering data mat file',fileparts(EBAC_DATA.datafilename));
  if ismac && ishandle(hinfo),
    delete(hinfo);
  end
  if ~ischar(n),
    delete(hObject);
    return;
  end
  EBAC_DATA.supervoxelfilename = fullfile(p,n);  
end

if ~exist(EBAC_DATA.supervoxelfilename,'file'),
  delete(hObject);
  return;
end

if ~isempty(handles.isanatomydir) && (handles.isanatomydir == 0),
  EBAC_DATA.anatomydir = '';
  fprintf('No access to per-line anatomy image directory.\n');
elseif ~exist(EBAC_DATA.anatomydir,'dir'),  
  res = questdlg('Do you have access to the per-line anatomy image directory?');
  if strcmpi(res,'yes'),
    fprintf('Select per-line anatomy image directory. Example: AverageAnatomyData20141028...\n');
    if ismac,
      hinfo = helpdlg('Select per-line anatomy image directory. Example: AverageAnatomyData20141028','Select data file');
    end
    EBAC_DATA.anatomydir = uigetdir('','Per-line anatomy image directory');
    if ismac && ishandle(hinfo),
      delete(hinfo);
    end
    if ~ischar(EBAC_DATA.anatomydir) || ~exist(EBAC_DATA.anatomydir,'dir')
      delete(hObject);
      return;
    end
  elseif strcmpi(res,'no'),
    EBAC_DATA.anatomydir = '';
  else
    delete(hObject);
    return;
  end
end

if EBAC_DATA.superuser > 0,
  fprintf('Running as super-user, you should have access to the Fly Light secure data\n');
  fprintf('Fly Light Secure Data directory (example: %s)...\n',EBAC_DATA.defaultflylightdir)
  if (isempty(EBAC_DATA.flylightdir) && ~exist(EBAC_DATA.defaultflylightdir,'dir')) || ...
      ( ~isempty(EBAC_DATA.flylightdir) && ~exist(EBAC_DATA.flylightdir,'dir')),
    EBAC_DATA.flylightdir = uigetdir('',sprintf('Fly Light Secure Data directory (example: %s)',EBAC_DATA.defaultflylightdir));
    if ~ischar(EBAC_DATA.flylightdir) || ~exist(EBAC_DATA.flylightdir,'dir')
      delete(hObject);
      return;
    end
  end
else
  EBAC_DATA.flylightdir = '';
end

% if ~exist(EBAC_DATA.linebehaviordir,'dir')
%   fprintf('Line-level Behavior Data directory (example: FlyBowlResults)...\n')
%   EBAC_DATA.linebehaviordir = uigetdir('',sprintf('Line-level Behavior Data directory (example: FlyBowlResults)'));
%   if ~ischar(EBAC_DATA.linebehaviordir) || ~exist(EBAC_DATA.linebehaviordir,'dir')
%     delete(hObject);
%     return;
%   end
% end

fprintf('Data locations used:\n');
fprintf('Mat file containing normalized behavior data: %s\n',EBAC_DATA.datafilename);
fprintf('Supervoxel clustering data mat file: %s\n',EBAC_DATA.supervoxelfilename);
if isempty(EBAC_DATA.anatomydir),
  fprintf('No per-line anatomy image directory.\n');
else
  fprintf('Per-line anatomy image directory: %s\n',EBAC_DATA.anatomydir);
end
if EBAC_DATA.superuser > 0,
  fprintf('Superuser: Fly Light Secure Data directory: %s\n',EBAC_DATA.flylightdir);
end
%fprintf('Line-level Behavior Data directory: %s\n',EBAC_DATA.linebehaviordir);
fprintf('You can change these directories under Edit -> Data locations.\n');

% files set, try loading!

SetStatus(handles,'Loading per-line behavior and anatomy info...');
EBAC_DATA.LoadNBData();
ClearStatus(handles);

handles.menu_view_modes = [handles.menu_view_maxzprojection,handles.menu_view_zslice,handles.menu_view_maxzsliceprojection,...
  handles.menu_view_maxyprojection,handles.menu_view_yslice,handles.menu_view_maxysliceprojection];
handles.axes_ButtonDownFcn = get(handles.axes_main,'ButtonDownFcn');

function handles = InitializeGUI(handles)

if ~ishandle(handles.figure1),
  return;
end

set(handles.figure1,'Name','BABAM!');

global EBAC_DATA;

if strcmpi(handles.viewmode,'zslice'),
  set(handles.edit_z,'String',num2str(handles.zslice));
elseif strcmpi(handles.viewmode,'xslice'),
  set(handles.edit_z,'String',num2str(handles.xslice));
else
  set(handles.edit_z,'String','');
end

[handles.sortedbehaviorlabels,handles.orderbehaviorlabels] = sort(EBAC_DATA.nbdata.behaviorlabels);

set(handles.popupmenu_behavior1,'String',handles.sortedbehaviorlabels);
set(handles.popupmenu_behavior2,'String',handles.sortedbehaviorlabels);

% set callback for slider motion
fcn = get(handles.slider_z,'Callback');
%handles.hslider_listener = handle.listener(handles.slider_z,'ActionEvent',fcn);
handles.hslider_listener = addlistener(handles.slider_z,...
  'ContinuousValueChange',fcn);

set(handles.slider_z,'Callback','');

% set callback for window motion
handles.windowmotioncallbackid = iptaddcallback(handles.figure1,'WindowButtonMotionFcn',@displaySuperVoxelInfo);
% windowmotionhandles = struct;
% windowmotionhandles.him_map = [];
% windowmotionhandles.axes_main = handles.axes_main;
% windowmotionhandles.text_supervoxelid = handles.text_supervoxelid;
% windowmotionhandles.text_compartment = handles.text_compartment;
% windowmotionhandles.text_pvalue = handles.text_pvalue;
% windowmotionhandles.text_pos = handles.text_pos;
% windowmotionhandles.contextmenu_axes_info = handles.contextmenu_axes_info;
% windowmotionhandles.windowmotioncallbackid = handles.windowmotioncallbackid;
setappdata(handles.figure1,'isinit',false);
%setappdata(handles.figure1,'windowmotionhandles',windowmotionhandles);

handles.menu_edit_datalocs_behaviordata = uimenu('Parent',handles.menu_edit_datalocs,...
  'Callback',@(varargin) SelectBehaviorDataFile(handles.menu_edit_datalocs,varargin{:}),...
  'Label','Behavior data mat file...');
handles.menu_edit_datalocs_anatomydir = uimenu('Parent',handles.menu_edit_datalocs,...
  'Callback',@SelectAnatomyDir,...
  'Label','Per-line anatomy image directory...');
handles.menu_edit_datalocs_supervoxeldata = uimenu('Parent',handles.menu_edit_datalocs,...
  'Callback',@(varargin) SelectSupervoxelDataFile(handles.menu_edit_datalocs,varargin{:}),...
  'Label','Supervoxel clustering data mat file...');
handles.menu_edit_datalocs_flylightdir = uimenu('Parent',handles.menu_edit_datalocs,...
  'Callback',@(varargin) SelectFlyLightDir(handles.menu_edit_datalocs,varargin{:}),...
  'Label','Fly Light data directory...');
% handles.menu_edit_datalocs_behaviordir = uimenu('Parent',handles.menu_edit_datalocs,...
%   'Callback',@(varargin) SelectBehaviorDir(handles.menu_edit_datalocs,varargin{:}),...
%   'Label','Fly Bowl behavior data directory...');

% set units to pixels -- this is for linux vs windows compatibility

for i = 1:numel(handles.uicontrols_in_pixels),
  set(handles.(handles.uicontrols_in_pixels{i}),'Units','pixels');
end

% get initial sizes of stuff
handles.sizeinfo = struct;
hs = findall(handles.figure1,'-property','Position');
for i = 1:numel(hs),
  fn = get(hs(i),'Tag');
  if isempty(fn),
    continue;
  end
  handles.sizeinfo.(fn) = get(hs(i),'Position');
end

if isfield(handles,'rcfigpos'),
  set(handles.figure1,'Position',handles.rcfigpos);
  figure1_ResizeFcn(handles.figure1, [], handles);
end

set(handles.edit_cluster_behthresh,'String',num2str(handles.cluster_behthresh));
set(handles.edit_cluster_anatthresh,'String',num2str(handles.cluster_anatthresh));
set(handles.edit_cluster_pvalthresh,'String',num2str(handles.cluster_pvalthresh));
set(handles.edit_cluster_k,'String',num2str(handles.cluster_k));

% if no pvalue data, disable showing correlated behaviors
if ~isfield(EBAC_DATA.nbdata,'pvaluedata'),
  set(handles.contextmenu_axes_showcorrbeh,'Enable','off');
end


handles.basiclogic_controls = [handles.popupmenu_behavior1,handles.popupmenu_behavior2,...
  handles.popupmenu_more1,handles.popupmenu_more2,handles.popupmenu_logic];
handles.advancedlogic_controls = handles.edit_behavior_logicalexpr;

SetLogicControlVisibility(handles);
if handles.isadvancedlogic,
  set(handles.checkbox_advanced,'Value',1);
else
  set(handles.checkbox_advanced,'Value',0);
end

function SetLogicControlVisibility(handles)

if handles.isadvancedlogic,
  set(handles.basiclogic_controls,'Visible','off');
  set(handles.advancedlogic_controls,'Visible','on');
else
  set(handles.basiclogic_controls,'Visible','on');
  set(handles.advancedlogic_controls,'Visible','off');
end

function handles = ResetGUI(handles)

global EBAC_DATA;
  
handles.behaviorstring = '';
handles.behavior1 = '';
handles.behavior2 = '';
handles.logic = '(None)';
handles.more1 = 'plus';
handles.more2 = 'plus';
handles.isadvancedlogic = false;

set(handles.popupmenu_behavior1,'Value',1,'String',handles.sortedbehaviorlabels);
set(handles.popupmenu_behavior2,'Value',1,'String',handles.sortedbehaviorlabels);
cla(handles.axes_main);
set(handles.axes_main,'Color','k');
setappdata(handles.figure1,'isinit',false);

% if no pvalue data, disable showing correlated behaviors
if isfield(EBAC_DATA.nbdata,'pvaluedata'),
  set(handles.contextmenu_axes_showcorrbeh,'Enable','on');
  set(handles.menu_analyze_showcorrelatedbehaviors,'Enable','on');
else
  set(handles.contextmenu_axes_showcorrbeh,'Enable','off');
  set(handles.menu_analyze_showcorrelatedbehaviors,'Enable','off');
end

SetLogicControlVisibility(handles);
set(handles.text_map_expr_corr,'Visible','off');
set(handles.text_showsupervoxelclustering,'Visible','off');
set(handles.pushbutton_stop_showsupervoxelclustering,'Visible','off');

handles = ClearState(handles,{'cluster','supervoxel'});

function SelectBehaviorDataFile(hObject,varargin)

handles = guidata(hObject);
[handles,ischange] = SelectBehaviorDataFile1(handles);

if ~ischange,
  guidata(hObject,handles);
  return;
end

%handles = SelectSupervoxelDataFile1(handles);

handles = ResetGUI(handles);

guidata(hObject,handles);

function handles = SelectSupervoxelDataFile(hObject,varargin)

handles = guidata(hObject);

[handles,ischange] = SelectSupervoxelDataFile1(handles);

if ~ischange,
  guidata(hObject,handles);
  return;
end

%handles = SelectBehaviorDataFile1(handles);

handles = ResetGUI(handles);

guidata(hObject,handles);


function [handles,ischange] = SelectBehaviorDataFile1(handles)

global EBAC_DATA;
ischange = false;
if exist(EBAC_DATA.datafilename,'file'),
  defaultfile = EBAC_DATA.datafilename;
else
  defaultfile = '';
end
[n,p] = uigetfile('*.mat','Behavior data mat file',defaultfile);
if ~ischar(n),
  return;
end
newdatafilename = fullfile(p,n);
if strcmp(newdatafilename,EBAC_DATA.datafilename),
  return;
end
EBAC_DATA.datafilename = newdatafilename;
SetStatus(handles,'Loading per-line behavior and anatomy info...');
EBAC_DATA.LoadNBData();
ClearStatus(handles);

ischange = true;

function [handles,ischange] = SelectSupervoxelDataFile1(handles)

global EBAC_DATA;
ischange = false;
if exist(EBAC_DATA.supervoxelfilename,'file'),
  defaultfile = EBAC_DATA.supervoxelfilename;
else
  defaultfile = '';
end
[n,p] = uigetfile('*.mat','Supervoxel clustering data mat file',defaultfile);
if ~ischar(n),
  return;
end
newsupervoxelfilename = fullfile(p,n);
if strcmp(newsupervoxelfilename,EBAC_DATA.supervoxelfilename),
  return;
end
EBAC_DATA.supervoxelfilename = newsupervoxelfilename;

ischange = true;

function SelectAnatomyDir(varargin)

global EBAC_DATA;
if exist(EBAC_DATA.anatomydir,'file'),
  defaultdir = EBAC_DATA.anatomydir;
else
  defaultdir = '';
end
newanatomydir = uigetdir(defaultdir,'Per-line anatomy image directory');
if ~ischar(newanatomydir),
  return;
end
if strcmp(newanatomydir,EBAC_DATA.anatomydir),
  return;
end
EBAC_DATA.anatomydir = newanatomydir;

function SelectFlyLightDir(varargin)

global EBAC_DATA;

if EBAC_DATA.superuser == 0,  
  uiwait(msgbox('Fly Light directory is not necessary for GUI operation. Only specify if you have access to the Fly Light Secure data'));
end

if exist(EBAC_DATA.flylightdir,'file'),
  defaultdir = EBAC_DATA.flylightdir;
else
  defaultdir = '';
end
newflylightdir = uigetdir(defaultdir,'Fly Light data directory (example: /tier2/flylight/screen)');
if ~ischar(newflylightdir),
  return;
end
% if strcmp(newflylightdir,EBAC_DATA.flylightdir),
%   return;
% end
oldflylightdir = EBAC_DATA.flylightdir;
EBAC_DATA.flylightdir = newflylightdir;
EBAC_DATA.SetFlyLightDir(oldflylightdir);

function SelectBehaviorDir(varargin)

warning('This function is obsolete');
return;

% global EBAC_DATA;
% if exist(EBAC_DATA.linebehaviordir,'file'),
%   defaultdir = EBAC_DATA.linebehaviordir;
% elseif exist(EBAC_DATA.defaultlinebehaviordir,'dir'),
%   defaultdir = EBAC_DATA.defaultlinebehaviordir;
% else
%   defaultdir = '';
% end
% newbehaviordir = uigetdir(defaultdir,sprintf('Behavior data directory (example: %s)',EBAC_DATA.defaultbehaviordir));
% if ~ischar(newbehaviordir),
%   return;
% end
% EBAC_DATA.linebehaviordir = newbehaviordir;

function handles = DisableInteraction(handles)

set(handles.axes_main,'Visible','off');
set(handles.slider_z,'Visible','off');
set(handles.popupmenu_logic,'Value',1);
set(handles.popupmenu_behavior2,'Enable','off');
set(handles.popupmenu_more2,'Enable','off');
set(handles.edit_z,'Visible','off');
set(handles.menu_file_export,'Enable','off');
set(handles.menu_view,'Enable','off');
set(handles.menu_analyze,'Enable','off');
set(handles.menu_edit_findsupervoxel,'Enable','off');

function displaySuperVoxelInfo(obj,evt,pt,useclusterid)  %#ok<*INUSD>

global EBAC_DATA;

isinit = getappdata(obj,'isinit');
if ~isinit,
  return;
end

handles = guidata(obj);

if ~isfield(handles,'him_map') || ~ishandle(handles.him_map) || isempty(EBAC_DATA),
  return;
end

if ~ishandle(handles.axes_main),
  iptremovecallback(obj,'WindowButtonMotionFcn',handles.windowmotioncallbackid);
  return;
end

if nargin < 3,
  pt = get(handles.axes_main,'CurrentPoint');
end
if nargin < 4,
  useclusterid = true;
end
xscreen = round(pt(1,1));
yscreen = round(pt(1,2));
xlim = get(handles.axes_main,'Xlim');
if xscreen < xlim(1) || xscreen > xlim(2),
  % TODO: clear status?
  return;
end
ylim = get(handles.axes_main,'Ylim');
if yscreen < ylim(1) || yscreen > ylim(2),
  % TODO: clear status?
  return;
end

% else display pixel info string as usual
im = getappdata(handles.him_map,'supervoxelid');
[nr,nc,~] = size(im);
if yscreen < 1 || yscreen > nr || xscreen < 1 || xscreen > nc,
  % TODO: clear status?
  return;
end

supervoxelid = im(yscreen,xscreen,1);
zscreen = im(yscreen,xscreen,2);
[x,y,z] = ScreenPos2ThreeDLoc(handles,xscreen,yscreen,zscreen);
if supervoxelid == 0,
  set(handles.text_supervoxelid,'String','');
  set(handles.text_compartment,'String','');
  set(handles.text_pos,'String',sprintf('(%3d,%3d,---)',x,y));
  set(handles.text_pvalue,'String','');
  setappdata(handles.him_map,'currentsupervoxel',{});
else
  compartmentid = im(yscreen,xscreen,3);
  compartment = EBAC_DATA.labeldata.maskdata.leg{compartmentid};
  set(handles.text_supervoxelid,'String',sprintf('%3d',supervoxelid));
  clusterid = 0;
  if useclusterid && strcmp(handles.datatype,'cluster') && isfield(EBAC_DATA.bamap,'clusterres'),
    clusterid = EBAC_DATA.bamap.clusterres.clusterid(supervoxelid);
  end
  if clusterid > 0,
    set(handles.text_label_compartment,'String','Cluster:');
    set(handles.text_compartment,'String',sprintf('%d (%s)',clusterid,compartment));
  else
    set(handles.text_label_compartment,'String','Compartment:');
    set(handles.text_compartment,'String',compartment);
  end
  set(handles.text_pos,'String',sprintf('(%3d,%3d,%3d)',x,y,z));
  pvalue = EBAC_DATA.bamap.pvalue_fdr(supervoxelid);
  set(handles.text_pvalue,'String',num2str(pvalue));  
  setappdata(handles.him_map,'currentsupervoxel',{supervoxelid,compartment,pvalue,[x,y,z],clusterid});
end
%fprintf('X = %d, Y = %d, C = %d\n',x,y,c);


function handles = EnableInteraction(handles)

set(handles.axes_main,'Visible','on');
if ismember(handles.viewmode,{'zslice','yslice','xslice'}),
  set(handles.slider_z,'Visible','on');
  set(handles.edit_z,'Visible','on');
else
  set(handles.slider_z,'Visible','off');
  set(handles.edit_z,'Visible','off');
end

set(handles.menu_file_export,'Enable','on');
set(handles.menu_view,'Enable','on');
set(handles.menu_analyze,'Enable','on');
set(handles.menu_edit_findsupervoxel,'Enable','on');


% --- Outputs from this function are returned to the command line.
function varargout = ExploreBehaviorAnatomyCorrelations_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isstruct(handles),
  varargout{1} = handles.output;
else
  varargout{1} = [];
end


% --- Executes on slider movement.
function slider_z_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to slider_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
v = max(1,round(get(hObject,'Value')));
switch handles.viewmode,
  case 'zslice'
    v = min(v,handles.zsz);
    if v == handles.zslice,
      return;
    end
    handles.zslice = v;
    set(handles.edit_z,'String',num2str(handles.zslice));
  case 'yslice'
    v = min(v,handles.ysz);
    if v == handles.yslice,
      return;
    end
    handles.yslice = v;
    set(handles.edit_z,'String',num2str(handles.yslice));
  otherwise
    error('Slider callback when not in slice mode!!');
end
handles = UpdateMap(handles);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function slider_z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_z_Callback(hObject, eventdata, handles)
% hObject    handle to edit_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_z as text
%        str2double(get(hObject,'String')) returns contents of edit_z as a double

v = str2double(get(hObject,'String'));

switch handles.viewmode,
  case 'zslice'
    maxv = handles.zsz;
  case 'yslice',
    maxv = handles.ysz;
end

if isnan(v) || v < 1 || v > maxv,
  switch handles.viewmode,
    case 'zslice'
      set(hObject,'String',num2str(handles.zslice));
    case 'yslice'
      set(hObject,'String',num2str(handles.yslice));
    otherwise
      error('Edit slice callback when not in slice mode!!');
  end
  return;
end

switch handles.viewmode,
  case 'zslice'
    if v == handles.zslice,
      return;
    end
    handles.zslice = v;
    set(handles.slider_z,'Value',handles.zslice);
  case 'yslice'
    handles.yslice = v;
    set(handles.slider_z,'Value',handles.yslice);
  otherwise
    error('Slider callback when not in slice mode!!');
end
handles = UpdateMap(handles);
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edit_z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function popupmenu_behavior1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_behavior1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of popupmenu_behavior1 as text
%        str2double(get(hObject,'String')) returns contents of popupmenu_behavior1 as a double


% --- Executes during object creation, after setting all properties.
function popupmenu_behavior1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_behavior1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
if ismac,
  set(hObject,'ForegroundColor','k','BackgroundColor','w');
end


% --- Executes on selection change in popupmenu_logic.
function popupmenu_logic_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_logic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_logic contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_logic
v = get(hObject,'Value');
if v == 1,
  set(handles.popupmenu_behavior2,'Enable','off');
  set(handles.popupmenu_more2,'Enable','off');
else
  set(handles.popupmenu_behavior2,'Enable','on');
  set(handles.popupmenu_more2,'Enable','on');
end

% --- Executes during object creation, after setting all properties.
function popupmenu_logic_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_logic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
if ismac,
  set(hObject,'ForegroundColor','k','BackgroundColor','w');
end

function popupmenu_behavior2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_behavior2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of popupmenu_behavior2 as text
%        str2double(get(hObject,'String')) returns contents of popupmenu_behavior2 as a double


% --- Executes during object creation, after setting all properties.
function popupmenu_behavior2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_behavior2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
if ismac,
  set(hObject,'ForegroundColor','k','BackgroundColor','w');
end


% --- Executes on button press in pushbutton_update.
function pushbutton_update_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_update (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.isadvancedlogic,  
  
  handles.behaviorstring = handles.behaviorstringcurr;
  handles.parse = handles.parsecurr;
  
  handles.behavior1 = handles.parse.behaviors{1};
  b1 = find(strcmp(handles.sortedbehaviorlabels,handles.behavior1));
  assert(numel(b1)==1);
  set(handles.popupmenu_behavior1,'Value',b1);
  
  handles.more1 = handles.parse.mores{1};
  m1 = find(strcmp(get(handles.popupmenu_more1,'String'),handles.more1));
  assert(numel(m1)==1);
  set(handles.popupmenu_more1,'Value',m1);
  
  if isempty(handles.parse.logics),
    handles.logic = '(None)';
    set(handles.popupmenu_behavior2,'Enable','off');
    set(handles.popupmenu_more2,'Enable','off');
  else
    handles.logic = handles.parse.logics{1};
    set(handles.popupmenu_behavior2,'Enable','on');
    set(handles.popupmenu_more2,'Enable','on');
  end
  l1 = find(strcmp(get(handles.popupmenu_logic,'String'),handles.logic));
  assert(numel(l1)==1);
  set(handles.popupmenu_logic,'Value',l1);
  
  if numel(handles.parse.behaviors) >= 2,
    handles.behavior2 = handles.parse.behaviors{2};
    b2 = find(strcmp(handles.sortedbehaviorlabels,handles.behavior2));
    assert(numel(b2)==1);
    set(handles.popupmenu_behavior2,'Value',b2);
    
    handles.more2 = handles.parse.mores{2};
    m2 = find(strcmp(get(handles.popupmenu_more2,'String'),handles.more2));
    assert(numel(m2)==1);
    set(handles.popupmenu_more2,'Value',m2);
  end

else
  
  b1 = get(handles.popupmenu_behavior1,'Value');
  b2 = get(handles.popupmenu_behavior2,'Value');
  handles.behavior1 = handles.sortedbehaviorlabels{b1};
  handles.behavior2 = handles.sortedbehaviorlabels{b2};
  l = get(handles.popupmenu_logic,'String');
  handles.logic = l{get(handles.popupmenu_logic,'Value')};
  m1 = get(handles.popupmenu_more1,'Value');
  if m1 == 1,
    handles.more1 = 'plus';
  else
    handles.more1 = 'minus';
  end
  m2 = get(handles.popupmenu_more2,'Value');
  if m2 == 1,
    handles.more2 = 'plus';
  else
    handles.more2 = 'minus';
  end
  
  if strcmpi(handles.logic,'(None)'),
    handles.behaviorstring = sprintf('{%s_%s}',handles.behavior1,handles.more1);
  else
    handles.behaviorstring = sprintf('{%s_%s} %s {%s_%s}',handles.behavior1,handles.more1,handles.logic,handles.behavior2,handles.more2);
  end
  
end

set(handles.menu_analyze_showcorrelatedbehaviors,'Label',sprintf('Show behaviors corr. w/ %s',handles.behaviorstring));

set(handles.edit_behavior_logicalexpr,'String',handles.behaviorstring);

handles = ComputeAndPlotMap(handles);

guidata(hObject,handles);

function handles = ComputeAndPlotMap(handles)

global EBAC_DATA;

SetStatus(handles,'Computing correlation p-values...');
EBAC_DATA.ComputeBAMap({handles.behaviorstring});
ClearStatus(handles);  

SetStatus(handles,'Mapping correlations...');
if handles.dologcmap,
  EBAC_DATA.bamap.behaviormap = BehaviorAnatomyMap(max(0,log10(handles.maxpvalue)-log10(EBAC_DATA.bamap.pvalue_fdr)),EBAC_DATA.labeldata.labels,nan);
else
  EBAC_DATA.bamap.behaviormap = BehaviorAnatomyMap(EBAC_DATA.bamap.pvalue_fdr,EBAC_DATA.labeldata.labels,1);
end
ClearStatus(handles);

handles.datatype = 'pvalue';

handles = ClearState(handles,{'cluster','supervoxel'});

handles = UpdateMap(handles);
handles = UpdateMaskBoundary(handles);
handles = UpdateMapScaling(handles);

function handles = ClearState(handles,cleartypes)

global EBAC_DATA;

if ismember('supervoxel',cleartypes),
  handles.currentsupervoxel = [];
  handles.maxprojz_svboundary = {};
  handles.svmaskid = -1;
  handles.exprcorrmap = [];
end
if ismember('cluster',cleartypes),
  EBAC_DATA.bamap.clusterres = struct;
  EBAC_DATA.bamap.clustermap = [];
end
set(handles.uipanel_cluster,'Visible','off');
set(handles.uipanel_supervoxel,'Visible','on');

function ClearStatus(handles)

if ~isstruct(handles) || ~isfield(handles,'figure1') || ~ishandle(handles.figure1) || ...
    ~strcmpi(get(handles.figure1,'Visible'),'on'),
  fprintf('Done.\n');
else
  set(handles.text_statusbar,'String','Ready','ForegroundColor',[.2,.8,.2]);
  drawnow;
end

function SetStatus(handles,varargin)

if numel(varargin) > 1,
  s = sprintf(varargin{:});
elseif isempty(varargin),
  s = '';
else
  s = varargin{1};
end

if ~isstruct(handles) || ~isfield(handles,'figure1') || ~ishandle(handles.figure1) || ...
    ~strcmpi(get(handles.figure1,'Visible'),'on'),
  fprintf([s,'\n']);
else
  set(handles.text_statusbar,'String',s,'ForegroundColor',[.8,.2,.8]);
  drawnow;
end


function SetStatusCallback(hObj,varargin)

handles = guidata(hObj);
SetStatus(handles,varargin{:});

function ClearStatusCallback(hObj,varargin)

handles = guidata(hObj);
ClearStatus(handles,varargin{:});


function handles = UpdateMap(handles)

global EBAC_DATA;

if isempty(EBAC_DATA.bamap),
  return;
end

isinit = getappdata(handles.figure1,'isinit');

if ~isinit,
  
  SetStatus(handles,'Initializing map...');
  
  [handles.ysz,handles.xsz,handles.zsz] = size(EBAC_DATA.bamap.behaviormap);
  handles.him_map = imagesc(zeros([handles.ysz,handles.xsz]),'Parent',handles.axes_main);
  set(handles.axes_main,'ButtonDownFcn',handles.axes_ButtonDownFcn);
  set(handles.him_map,'ButtonDownFcn',handles.axes_ButtonDownFcn,'UIContextMenu',get(handles.axes_main,'UIContextMenu'));
  axis(handles.axes_main,'image');
  box(handles.axes_main,'off');
  hold(handles.axes_main,'on');
  handles.hmaskboundary = plot(handles.axes_main,nan,nan,'w-','HitTest','off');
  handles.hsvboundary = plot(handles.axes_main,nan,nan,'w-','HitTest','off');
  handles.htitle = title(handles.axes_main,handles.behaviorstring,'Interpreter','none');
  
  handles = UpdateMaskBoundary(handles);
  handles = UpdateMapScaling(handles);
  
  setappdata(handles.figure1,'isinit',true);
  
  handles = EnableInteraction(handles);
  handles = UpdateView(handles);
  
  ClearStatus(handles);
  
end

switch handles.viewmode,
  
  case 'maxzprojection'
   
    SetStatus(handles,'Updating map...');
    
    switch handles.datatype,
      case 'pvalue',
        if handles.dologcmap,
          [maxproj,idx] = max(EBAC_DATA.bamap.behaviormap,[],3);
        else
          [maxproj,idx] = min(EBAC_DATA.bamap.behaviormap,[],3);
        end
      case 'exprcorr',
        [maxproj,idx] = max(EBAC_DATA.bamap.exprcorrmap,[],3);
      case 'cluster',
        [maxproj,idx] = max(EBAC_DATA.bamap.clustermap,[],3);
      case 'supervoxel',
        error('This should never happen!');
    end
    
    idx2 = sub2ind([handles.ysz*handles.xsz,handles.zsz],1:handles.ysz*handles.xsz,idx(:)');
    supervoxelid = reshape(EBAC_DATA.labeldata.labels(idx2),[handles.ysz,handles.xsz]);
    compartmentid = single(reshape(EBAC_DATA.labeldata.maskdata.mask(idx2),[handles.ysz,handles.xsz]));
    
    set(handles.him_map,'CData',maxproj);
    setappdata(handles.him_map,'supervoxelid',cat(3,supervoxelid,idx,compartmentid));
    
    ClearStatus(handles);

  case 'zslice'

    switch handles.datatype,
      case 'pvalue',
        set(handles.him_map,'CData',EBAC_DATA.bamap.behaviormap(:,:,handles.zslice));
      case 'exprcorr',
        set(handles.him_map,'CData',EBAC_DATA.bamap.exprcorrmap(:,:,handles.zslice));
      case 'cluster'
        set(handles.him_map,'CData',EBAC_DATA.bamap.clustermap(:,:,handles.zslice));
      case 'supervoxels',
        set(handles.him_map,'CData',EBAC_DATA.labeldata.imcolor(:,:,handles.zslice));
    end

    supervoxelid = EBAC_DATA.labeldata.labels(:,:,handles.zslice);
    compartmentid = single(EBAC_DATA.labeldata.maskdata.mask(:,:,handles.zslice));
    
    setappdata(handles.him_map,'supervoxelid',cat(3,supervoxelid,repmat(handles.zslice,[handles.ysz,handles.xsz]),compartmentid));
    
    
  case 'maxzsliceprojection'
    
    SetStatus(handles,'Updating map...');
    
    switch handles.datatype,
      case 'pvalue',
        if handles.dologcmap,
          fun = 'max';
        else
          fun = 'min';
          %[maxproj,idx] = min(EBAC_DATA.bamap.behaviormap,[],3);
        end
        [maxsliceproj,handles.slice_z0s,handles.slice_z1s,idx] = SlicedMaxProjection(EBAC_DATA.bamap.behaviormap,...
          handles.nslices,'fun',fun,'dir',3);
      case 'exprcorr',
        [maxsliceproj,handles.slice_z0s,handles.slice_z1s,idx] = SlicedMaxProjection(EBAC_DATA.bamap.exprcorrmap,...
          handles.nslices,'fun','max','dir',3);
         %[maxproj,idx] = max(EBAC_DATA.bamap.exprcorrmap,[],3);
      case 'cluster',
        [maxsliceproj,handles.slice_z0s,handles.slice_z1s,idx] = SlicedMaxProjection(EBAC_DATA.bamap.clustermap,...
          handles.nslices,'fun','max','dir',3);
      case 'supervoxels',
        error('This should never happen!');
        %[maxproj,idx] = max(EBAC_DATA.bamap.clustermap,[],3);
    end

    supervoxelid = nan([handles.ysz,handles.xsz,handles.nslices],'single');
    compartmentid = nan([handles.ysz,handles.xsz,handles.nslices],'single');
    handles.slicey = repmat((1:handles.ysz)',[handles.nslices,1]);
    handles.slicey = handles.slicey(:);
    for slicei = 1:handles.nslices,
      idx2 = sub2ind([handles.ysz*handles.xsz,handles.zsz],1:handles.ysz*handles.xsz,...
        reshape(idx(:,:,:,slicei),[1,handles.ysz*handles.xsz]));
      supervoxelid(:,:,slicei) = reshape(EBAC_DATA.labeldata.labels(idx2),[handles.ysz,handles.xsz]);
      compartmentid(:,:,slicei) = single(reshape(EBAC_DATA.labeldata.maskdata.mask(idx2),[handles.ysz,handles.xsz]));
    end
    maxproj = reshape(permute(maxsliceproj,[1,4,2,3]),[handles.ysz*handles.nslices,handles.xsz]);
    idx = reshape(permute(idx,[1,4,2,3]),[handles.ysz*handles.nslices,handles.xsz]);
    supervoxelid = reshape(permute(supervoxelid,[1,3,2]),[handles.ysz*handles.nslices,handles.xsz]);
    compartmentid = reshape(permute(compartmentid,[1,3,2]),[handles.ysz*handles.nslices,handles.xsz]);

    set(handles.him_map,'CData',maxproj);
    setappdata(handles.him_map,'supervoxelid',cat(3,supervoxelid,idx,compartmentid));
    
    ClearStatus(handles);
    
  case 'maxyprojection',
    
    SetStatus(handles,'Updating map...');

    switch handles.datatype,
      case 'pvalue',
        if handles.dologcmap,
          [maxproj,idx] = max(EBAC_DATA.bamap.behaviormap,[],1);
        else
          [maxproj,idx] = min(EBAC_DATA.bamap.behaviormap,[],1);
        end
      case 'exprcorr',
        [maxproj,idx] = max(EBAC_DATA.bamap.exprcorrmap,[],1);
      case 'cluster',
        [maxproj,idx] = max(EBAC_DATA.bamap.clustermap,[],1);        
      case 'supervoxels',
        error('This should never happen!');
    end
        
    idx2 = sub2ind([handles.ysz,handles.xsz*handles.zsz],idx(:)',1:handles.xsz*handles.zsz);
    supervoxelid = reshape(EBAC_DATA.labeldata.labels(idx2),[handles.xsz,handles.zsz])';
    compartmentid = single(reshape(EBAC_DATA.labeldata.maskdata.mask(idx2),[handles.xsz,handles.zsz]))';
    
    set(handles.him_map,'CData',permute(maxproj,[3,2,1]));
    setappdata(handles.him_map,'supervoxelid',cat(3,supervoxelid,reshape(idx,handles.xsz,handles.zsz)',compartmentid));
    
    ClearStatus(handles);

  case 'yslice'

    switch handles.datatype,
      case 'pvalue',
        set(handles.him_map,'CData',permute(EBAC_DATA.bamap.behaviormap(handles.yslice,:,:),[3,2,1]));
      case 'exprcorr',
        set(handles.him_map,'CData',permute(EBAC_DATA.bamap.exprcorrmap(handles.yslice,:,:),[3,2,1]));
      case 'cluster',
        set(handles.him_map,'CData',permute(EBAC_DATA.bamap.clustermap(handles.yslice,:,:),[3,2,1]));
      case 'supervoxels',
        set(handles.him_map,'CData',permute(EBAC_DATA.labeldata.imcolor(handles.yslice,:,:),[3,2,1]));
    end
    supervoxelid = permute(EBAC_DATA.labeldata.labels(handles.yslice,:,:),[3,2,1]);
    compartmentid = permute(single(EBAC_DATA.labeldata.maskdata.mask(handles.yslice,:,:)),[3,2,1]);
    setappdata(handles.him_map,'supervoxelid',cat(3,supervoxelid,repmat(handles.yslice,[handles.zsz,handles.xsz]),compartmentid));
    
  case 'maxysliceprojection'
    
    SetStatus(handles,'Updating map...');
    
    switch handles.datatype,
      case 'pvalue',
        if handles.dologcmap,
          fun = 'max';
        else
          fun = 'min';
          %[maxproj,idx] = min(EBAC_DATA.bamap.behaviormap,[],3);
        end
        [maxsliceproj,handles.slice_y0s,handles.slice_y1s,idx] = SlicedMaxProjection(EBAC_DATA.bamap.behaviormap,...
          handles.nslices,'fun',fun,'dir',1);
      case 'exprcorr',
        [maxsliceproj,handles.slice_y0s,handles.slice_y1s,idx] = SlicedMaxProjection(EBAC_DATA.bamap.exprcorrmap,...
          handles.nslices,'fun','max','dir',1);
        %[maxproj,idx] = max(EBAC_DATA.bamap.exprcorrmap,[],3);
      case 'cluster',
        [maxsliceproj,handles.slice_y0s,handles.slice_y1s,idx] = SlicedMaxProjection(EBAC_DATA.bamap.clustermap,...
          handles.nslices,'fun','max','dir',1);
        %[maxproj,idx] = max(EBAC_DATA.bamap.clustermap,[],3);
      case 'supervoxels',
        error('This should never happen!');
    end
    
    handles.slicez = repmat((1:handles.zsz)',[handles.nslices,1]);
    handles.slicez = handles.slicez(:);
    supervoxelid = nan([handles.xsz,handles.zsz,handles.nslices],'single');
    compartmentid = nan([handles.xsz,handles.zsz,handles.nslices],'single');
    for slicei = 1:handles.nslices,      
      idx2 = sub2ind([handles.ysz,handles.xsz*handles.zsz],...
        reshape(idx(:,:,:,slicei),[1,handles.xsz*handles.zsz]),1:handles.xsz*handles.zsz);
      supervoxelid(:,:,slicei) = reshape(EBAC_DATA.labeldata.labels(idx2),[handles.xsz,handles.zsz]);
      compartmentid(:,:,slicei) = single(reshape(EBAC_DATA.labeldata.maskdata.mask(idx2),[handles.xsz,handles.zsz]));
    end
    maxproj = reshape(maxsliceproj,[handles.xsz,handles.zsz*handles.nslices]);
    idx = reshape(idx,[handles.xsz,handles.zsz*handles.nslices])';
    supervoxelid = reshape(supervoxelid,[handles.xsz,handles.zsz*handles.nslices])';
    compartmentid = reshape(compartmentid,[handles.xsz,handles.zsz*handles.nslices])';
    
    set(handles.him_map,'CData',maxproj');
    setappdata(handles.him_map,'supervoxelid',cat(3,supervoxelid,idx,compartmentid));
    
    ClearStatus(handles);
    
end

set(handles.htitle,'String',handles.behaviorstring);

if strcmp(handles.datatype,'cluster'),
  set(handles.uipanel_cluster,'Visible','on');
  set(handles.uipanel_supervoxel,'Visible','off');
else
  set(handles.uipanel_cluster,'Visible','off');
  set(handles.uipanel_supervoxel,'Visible','on');
end
if strcmp(handles.datatype,'exprcorr'),
  set(handles.text_map_expr_corr,'Visible','on');
  set(handles.pushbutton_stop_map_expr_corr,'Visible','on');
else
  set(handles.text_map_expr_corr,'Visible','off');
  set(handles.pushbutton_stop_map_expr_corr,'Visible','off');
end
 
if strcmp(handles.datatype,'supervoxels'),
  set(handles.text_showsupervoxelclustering,'Visible','on');
  set(handles.pushbutton_stop_showsupervoxelclustering,'Visible','on');
else
  set(handles.text_showsupervoxelclustering,'Visible','off');
  set(handles.pushbutton_stop_showsupervoxelclustering,'Visible','off');
end


function handles = UpdateView(handles)

set(handles.menu_view_modes,'Checked','off');

switch handles.viewmode,
  case 'maxzprojection',
    set(handles.menu_view_maxzprojection,'Checked','on');
    set(handles.slider_z,'Visible','off');
    set(handles.edit_z,'Visible','off');
  case 'zslice',
    set(handles.menu_view_zslice,'Checked','on');
    sliderstep = [1/(handles.zsz-1),min(1,20/(handles.zsz-1))];
    set(handles.slider_z,'Visible','on','Min',1,'Max',handles.zsz,'SliderStep',sliderstep,'Value',handles.zslice);
    set(handles.edit_z,'Visible','on','String',num2str(handles.zslice));
  case 'maxzsliceprojection',
    set(handles.menu_view_maxzsliceprojection,'Checked','on');
    set(handles.slider_z,'Visible','off');
    set(handles.edit_z,'Visible','off');
  case 'maxyprojection',
    set(handles.menu_view_maxyprojection,'Checked','on');
    set(handles.slider_z,'Visible','off');
    set(handles.edit_z,'Visible','off');
  case 'yslice',
    set(handles.menu_view_yslice,'Checked','on');
    sliderstep = [1/(handles.ysz-1),min(1,20/(handles.ysz-1))];
    set(handles.slider_z,'Visible','on','Min',1,'Max',handles.ysz,'SliderStep',sliderstep,'Value',handles.yslice);
    set(handles.edit_z,'Visible','on','String',num2str(handles.yslice));    
  case 'maxysliceprojection',
    set(handles.menu_view_maxysliceprojection,'Checked','on');
    set(handles.slider_z,'Visible','off');
    set(handles.edit_z,'Visible','off');
end

handles = UpdateMaskBoundary(handles);

function handles = UpdateMaskBoundary(handles,showsv,showcluster)

if nargin < 2,
  showsv = false;
end
if nargin < 3,
  showcluster = true;
end

global EBAC_DATA;

if ismember(handles.viewmode,{'maxzprojection','zslice'}),
  newmasktype = 'maxzproj';
elseif ismember(handles.viewmode,{'maxzsliceprojection'}),
  newmasktype = 'maxzsliceproj';
elseif ismember(handles.viewmode,{'maxysliceprojection'}),
  newmasktype = 'maxysliceproj';
else
  newmasktype = 'maxyproj';
end

if isfield(handles,'currentsupervoxel'),
  svinfo = handles.currentsupervoxel;
else
  svinfo = [];
end
if (showsv || ismember(handles.datatype,{'exprcorr','cluster'})) && ~isempty(svinfo),
  
  supervoxelid = svinfo{1};
  if numel(svinfo) > 4 && showcluster,
    clusterid = svinfo{5};
  else
    clusterid = 0;
  end
  set(handles.hsvboundary,'Visible','on');

  if ~strcmp(handles.svmasktype,newmasktype) || ...
      ((clusterid==0) && handles.svmaskid ~= supervoxelid) || ...
      ((clusterid>0) && handles.svmaskid ~= clusterid),
    
    SetStatus(handles,'Updating supervoxel mask boundaries...');
    
    switch newmasktype,
      case 'maxzproj',
        if clusterid == 0,
          handles.maxprojz_svboundary = ComputeMaxProjSVBoundary(EBAC_DATA.labeldata.labels,supervoxelid,3);
        else
          handles.maxprojz_svboundary = ComputeMaxProjSVBoundary(EBAC_DATA.bamap.clustermap,clusterid,3);
        end
        tmpx = [];
        tmpy = [];
        for tmpi = 1:numel(handles.maxprojz_svboundary),
          tmpx = [tmpx;nan;handles.maxprojz_svboundary{tmpi}(:,2)]; %#ok<AGROW>
          tmpy = [tmpy;nan;handles.maxprojz_svboundary{tmpi}(:,1)]; %#ok<AGROW>
        end
        set(handles.hsvboundary,'XData',tmpx,'YData',tmpy);
      case 'maxyproj',
        % this is done on the symmetric mask, which is transposed
        if clusterid == 0,
          handles.maxprojy_svboundary = ComputeMaxProjSVBoundary(EBAC_DATA.labeldata.labels,supervoxelid,1);
        else
          handles.maxprojy_svboundary = ComputeMaxProjSVBoundary(EBAC_DATA.bamap.clustermap,clusterid,1);
        end
        tmpx = [];
        tmpy = [];
        for tmpi = 1:numel(handles.maxprojy_svboundary),
          tmpx = [tmpx;nan;handles.maxprojy_svboundary{tmpi}(:,1)]; %#ok<AGROW>
          tmpy = [tmpy;nan;handles.maxprojy_svboundary{tmpi}(:,2)]; %#ok<AGROW>
        end
        set(handles.hsvboundary,'XData',tmpx,'YData',tmpy);
      case 'maxzsliceproj',
        if ~isfield(handles,'slice_z0s'),
          [~,handles.slice_z0s,handles.slice_z1s] = SlicedMaxProjection(EBAC_DATA.bamap.behaviormap,...
            handles.nslices,'dir',3);
        end
        handles.maxsliceprojz_svboundary = {};
        if clusterid == 0,
          for tmpi = 1:handles.nslices,
            tmp = ComputeMaxProjSVBoundary(EBAC_DATA.labeldata.labels,supervoxelid,3,handles.slice_z0s(tmpi),handles.slice_z1s(tmpi));
            for tmpj = 1:numel(tmp),
              tmp{tmpj}(:,1) = tmp{tmpj}(:,1) + (tmpi-1)*handles.ysz;
            end
            handles.maxsliceprojz_svboundary = [handles.maxsliceprojz_svboundary;tmp];
          end
        else
          for tmpi = 1:handles.nslices,
            tmp = ComputeMaxProjSVBoundary(EBAC_DATA.bamap.clustermap,clusterid,3,handles.slice_z0s(tmpi),handles.slice_z1s(tmpi));
            for tmpj = 1:numel(tmp),
              tmp{tmpj}(:,1) = tmp{tmpj}(:,1) + (tmpi-1)*handles.ysz;
            end
            handles.maxsliceprojz_svboundary = [handles.maxsliceprojz_svboundary;tmp];
          end
        end
        tmpx = [];
        tmpy = [];
        for tmpi = 1:numel(handles.maxsliceprojz_svboundary),
          tmpx = [tmpx;nan;handles.maxsliceprojz_svboundary{tmpi}(:,2)]; %#ok<AGROW>
          tmpy = [tmpy;nan;handles.maxsliceprojz_svboundary{tmpi}(:,1)]; %#ok<AGROW>
        end
        set(handles.hsvboundary,'XData',tmpx,'YData',tmpy);

        
      case 'maxysliceproj',
        
        if ~isfield(handles,'slice_y0s'),
          [~,handles.slice_y0s,handles.slice_y1s] = SlicedMaxProjection(EBAC_DATA.bamap.behaviormap,...
            handles.nslices,'dir',1);
        end
        handles.maxsliceprojy_svboundary = {};
        if clusterid == 0,
          for tmpi = 1:handles.nslices,
            tmp = ComputeMaxProjSVBoundary(EBAC_DATA.labeldata.labels,supervoxelid,1,[],[],handles.slice_y0s(tmpi),handles.slice_y1s(tmpi));
            for tmpj = 1:numel(tmp),
              tmp{tmpj}(:,2) = tmp{tmpj}(:,2) + (tmpi-1)*handles.zsz;
            end
            handles.maxsliceprojy_svboundary = [handles.maxsliceprojy_svboundary;tmp];
          end
        else
          for tmpi = 1:handles.nslices,
            tmp = ComputeMaxProjSVBoundary(EBAC_DATA.bamap.clustermap,clusterid,1,[],[],handles.slice_y0s(tmpi),handles.slice_y1s(tmpi));
            for tmpj = 1:numel(tmp),
              tmp{tmpj}(:,1) = tmp{tmpj}(:,1) + (tmpi-1)*handles.zsz;
            end
            handles.maxsliceprojy_svboundary = [handles.maxsliceprojy_svboundary;tmp];
          end
        end
        tmpx = [];
        tmpy = [];
        for tmpi = 1:numel(handles.maxsliceprojy_svboundary),
          tmpx = [tmpx;nan;handles.maxsliceprojy_svboundary{tmpi}(:,1)]; %#ok<AGROW>
          tmpy = [tmpy;nan;handles.maxsliceprojy_svboundary{tmpi}(:,2)]; %#ok<AGROW>
        end
        set(handles.hsvboundary,'XData',tmpx,'YData',tmpy);
        
    end
    
    ClearStatus(handles);
    
    handles.svmasktype = newmasktype;
    if clusterid == 0,
      handles.svmaskid = supervoxelid;
    else
      handles.svmaskid = clusterid;
    end
    
  end
  
else
  
  set(handles.hsvboundary,'Visible','off');
  
end


if strcmp(handles.masktype,newmasktype),
  return;
end

SetStatus(handles,'Updating mask boundaries...');

switch newmasktype,
  case 'maxzproj',
    if ~isfield(handles,'maxprojz_maskboundary'),
      handles.maxprojz_maskboundary = ComputeMaxProjMaskBoundary(EBAC_DATA.labeldata.maskdata);
    end
    tmpx = [];
    tmpy = [];
    for tmpi = 1:numel(handles.maxprojz_maskboundary),
      tmpx = [tmpx;nan;handles.maxprojz_maskboundary{tmpi}(:,1)]; %#ok<AGROW>
      tmpy = [tmpy;nan;handles.maxprojz_maskboundary{tmpi}(:,2)]; %#ok<AGROW>
    end
    set(handles.hmaskboundary,'XData',tmpx,'YData',tmpy);
    set(handles.axes_main,'YLim',[.5,handles.ysz+.5]);
  case 'maxyproj',
    if ~isfield(handles,'maxprojy_maskboundary'),
      % this is done on the symmetric mask, which is transposed
      handles.maxprojy_maskboundary = ComputeMaxProjMaskBoundary(EBAC_DATA.labeldata.maskdata,2);
    end
    tmpx = [];
    tmpy = [];
    for tmpi = 1:numel(handles.maxprojy_maskboundary),
      tmpx = [tmpx;nan;handles.maxprojy_maskboundary{tmpi}(:,1)]; %#ok<AGROW>
      tmpy = [tmpy;nan;handles.maxprojy_maskboundary{tmpi}(:,2)]; %#ok<AGROW>
    end
    set(handles.hmaskboundary,'XData',tmpx,'YData',tmpy);
    set(handles.axes_main,'YLim',[.5,handles.zsz+.5]);
    
  case 'maxzsliceproj',
    if ~isfield(handles,'maxsliceprojz_maskboundary'),
      if ~isfield(handles,'slice_z0s'),
        [~,handles.slice_z0s,handles.slice_z1s] = SlicedMaxProjection(EBAC_DATA.bamap.behaviormap,...
          handles.nslices,'dir',3);
      end
      handles.maxsliceprojz_maskboundary = {};
      for slicei = 1:handles.nslices,
        tmp = ComputeMaxProjMaskBoundary(EBAC_DATA.labeldata.maskdata,3,handles.slice_z0s(slicei),handles.slice_z1s(slicei));
        for tmpi = 1:numel(tmp),
          tmp{tmpi}(:,2) = tmp{tmpi}(:,2) + (slicei-1)*handles.ysz;
        end
        handles.maxsliceprojz_maskboundary = [handles.maxsliceprojz_maskboundary;tmp];
      end
    end
    tmpx = [];
    tmpy = [];
    for tmpi = 1:numel(handles.maxsliceprojz_maskboundary),
      tmpx = [tmpx;nan;handles.maxsliceprojz_maskboundary{tmpi}(:,1)]; %#ok<AGROW>
      tmpy = [tmpy;nan;handles.maxsliceprojz_maskboundary{tmpi}(:,2)]; %#ok<AGROW>
    end
    set(handles.hmaskboundary,'XData',tmpx,'YData',tmpy);
    set(handles.axes_main,'YLim',[.5,handles.ysz*handles.nslices+.5]);    

  case 'maxysliceproj',
    if ~isfield(handles,'maxsliceprojy_maskboundary'),
      if ~isfield(handles,'slice_y0s'),
        [~,handles.slice_y0s,handles.slice_y1s] = SlicedMaxProjection(EBAC_DATA.bamap.behaviormap,...
          handles.nslices,'dir',1);
      end
      handles.maxsliceprojy_maskboundary = {};
      for slicei = 1:handles.nslices,
        tmp = ComputeMaxProjMaskBoundary(EBAC_DATA.labeldata.maskdata,2,[],[],...
          handles.slice_y0s(slicei),handles.slice_y1s(slicei));
        for tmpi = 1:numel(tmp),
          tmp{tmpi}(:,2) = tmp{tmpi}(:,2) + (slicei-1)*handles.zsz;
        end
        handles.maxsliceprojy_maskboundary = [handles.maxsliceprojy_maskboundary;tmp];
      end
    end
    tmpx = [];
    tmpy = [];
    for tmpi = 1:numel(handles.maxsliceprojy_maskboundary),
      tmpx = [tmpx;nan;handles.maxsliceprojy_maskboundary{tmpi}(:,1)]; %#ok<AGROW>
      tmpy = [tmpy;nan;handles.maxsliceprojy_maskboundary{tmpi}(:,2)]; %#ok<AGROW>
    end
    set(handles.hmaskboundary,'XData',tmpx,'YData',tmpy);
    set(handles.axes_main,'YLim',[.5,handles.zsz*handles.nslices+.5]);
    
end

handles.masktype = newmasktype;

ClearStatus(handles);

function handles = UpdateMapScaling(handles)

global EBAC_DATA;

switch handles.datatype,
  
  case 'pvalue',
    
    if handles.dologcmap,
      clim = [0,log10(handles.maxpvalue)-log10(handles.minpvalue)];
      cm = kjet(256);
    else
      clim = [handles.minpvalue,handles.maxpvalue];
      cm = flipud(kjet(256));
    end
    set(handles.hmaskboundary,'Color','w');
    set(handles.hsvboundary,'Color','w');
    
  case 'exprcorr',

    v = max(abs(EBAC_DATA.bamap.exprcorrmap(:)));
    clim = [-v,v];
    cm = myredbluecmap(256);
    set(handles.hmaskboundary,'Color','k');
    set(handles.hsvboundary,'Color','k');
    
  case 'cluster'
    clim = [0,handles.cluster_k];
    cm = jet(handles.cluster_k);
    cm = [0,0,0;cm(randperm(handles.cluster_k),:)];
    set(handles.hmaskboundary,'Color','w');
    set(handles.hsvboundary,'Color','w');
    
  case 'supervoxels'
    ncolors = max(EBAC_DATA.labeldata.coloring);
    clim = [0,ncolors];
    cm = jet(ncolors);
    cm = [0,0,0;cm(randperm(ncolors),:)];
    set(handles.hmaskboundary,'Color','w');
    set(handles.hsvboundary,'Color','w');
    end
set(handles.axes_main,'CLim',clim);
colormap(handles.axes_main,cm);

% TODO: do something with these: colorbar?
pvalueslabel = handles.pvalueslabel;
pvaluelabels = handles.pvaluelabels;
idxremove = pvalueslabel < handles.minpvalue | pvalueslabel > handles.maxpvalue;
pvalueslabel(idxremove) = [];
pvaluelabels(idxremove) = [];
if isempty(pvaluelabels),
  pvaluelabels = strtrim(cellstr(num2str(pvalueslabel(:))));
  pvaluelabels = regexprep(pvaluelabels,'^0.','.');
end


% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_view_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_view_maxzprojection_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_maxzprojection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmpi(handles.viewmode,'maxzprojection'),
  return;
end
handles.viewmode = 'maxzprojection';
handles = UpdateView(handles);
handles = UpdateMap(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_view_zslice_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_zslice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmpi(handles.viewmode,'zslice'),
  return;
end
handles.viewmode = 'zslice';
handles = UpdateView(handles);
handles = UpdateMap(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_view_maxyprojection_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_maxyprojection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmpi(handles.viewmode,'maxyprojection'),
  return;
end
handles.viewmode = 'maxyprojection';
handles = UpdateView(handles);
handles = UpdateMap(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_view_yslice_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_yslice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmpi(handles.viewmode,'yslice'),
  return;
end
handles.viewmode = 'yslice';
handles = UpdateView(handles);
handles = UpdateMap(handles);
guidata(hObject,handles);


% --- Executes on selection change in popupmenu_more1.
function popupmenu_more1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_more1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_more1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_more1


% --- Executes during object creation, after setting all properties.
function popupmenu_more1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_more1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_more2.
function popupmenu_more2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_more2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_more2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_more2


% --- Executes during object creation, after setting all properties.
function popupmenu_more2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_more2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% 
% % --- Executes on mouse press over axes background.
% function axes_main_ButtonDownFcn(hObject, eventdata, handles)
% % hObject    handle to axes_main (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% isinit = getappdata(handles.figure1,'isinit');
% 
% if ~isinit,
%   return;
% end
% 
% if ~strcmpi(get(handles.figure1,'SelectionType'),'alt'),
%   return;
% end
% 
% fprintf('Right click!\n');


% --------------------------------------------------------------------
function contextmenu_axes_showlines_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_axes_showlines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;

svinfo = handles.currentsupervoxel;
if isempty(svinfo),
  return;
end

supervoxelid = svinfo{1};
compartment = svinfo{2};
pvalue = svinfo{3};
if numel(svinfo) > 4,
  clusterid = svinfo{5};
else
  clusterid = 0;
end
%fprintf('Supervoxel %d, cluster %d in %s, p = %f\n',supervoxelid,clusterid,compartment,pvalue);

if clusterid > 0,
  svdata = EBAC_DATA.bamap.supervoxeldata(:,EBAC_DATA.bamap.clusterres.clusterid==clusterid);
  SetStatus(handles,'Finding important lines for cluster %d...',clusterid);
else
  svdata = EBAC_DATA.bamap.supervoxeldata(:,supervoxelid);
  SetStatus(handles,'Finding important lines for supervoxel %d in %s, p = %f',supervoxelid,compartment,pvalue);
end

[order,csfracba] = FindImporantLinesForSupervoxels(svdata,EBAC_DATA.bamap.normbehaviordata);
inflineidx = order(1:find(csfracba>=handles.thresh_ba_explained,1));
if numel(inflineidx) > handles.maxnlinesshow,
  inflineidx = inflineidx(1:handles.maxnlinesshow);
end

SetStatus(handles,'Creating line info webpage...');
behaviorstring = regexprep(handles.behaviorstring,'\W+','');
if clusterid > 0,
  filenamecurr = fullfile(tempdir,sprintf('LinesImportant_%s_Cluster%d.html',behaviorstring,clusterid));
else
  filenamecurr = fullfile(tempdir,sprintf('LinesImportant_%s_SV%d.html',behaviorstring,supervoxelid));
end
behaviorstring = strtrim(regexprep(handles.behaviorstring,'\W+',' '));
if clusterid > 0,
  groupname = sprintf('Lines important for behavior %s and cluster %d correlation',behaviorstring,clusterid);
else
  groupname = sprintf('Lines important for behavior %s and supervoxel %d correlation',behaviorstring,supervoxelid);
end

[ism,behaviorjs] = ismember(EBAC_DATA.bamap.behaviorfns{1},EBAC_DATA.nbdata.behaviorlabels);
isplus = strcmp(EBAC_DATA.bamap.stattypes{1},'plus');
assert(all(ism));
lineinfostrs = cell(1,numel(inflineidx));
for ii = 1:numel(inflineidx),
  
  linei = inflineidx(ii);
  s = '';
  for jj = 1:numel(behaviorjs),
    j = behaviorjs(jj);
    if isplus(jj),
      s = [s,sprintf('%s_%s = %.3f, ',EBAC_DATA.bamap.behaviorfns{1}{jj},...
        EBAC_DATA.bamap.stattypes{1}{jj},...
        EBAC_DATA.nbdata.normbehaviordata_plus(linei,j))];
    else
      s = [s,sprintf('%s_%s = %.3f, ',EBAC_DATA.bamap.behaviorfns{1}{jj},...
        EBAC_DATA.bamap.stattypes{1}{jj},...
        EBAC_DATA.nbdata.normbehaviordata_minus(linei,j))];
    end
  end
  lineinfostrs{ii} = s(1:end-2);  
end

if isfield(EBAC_DATA.nbdata,'metadata'),
  MakeLineInfoWebpage(EBAC_DATA.nbdata.line_names_curr(inflineidx),'outfilename',filenamecurr,...
    'groupname',groupname,'imdata',EBAC_DATA.nbdata.imdata,'imdata_vnc',EBAC_DATA.nbdata.imdata_vnc,...
    'metadata',EBAC_DATA.nbdata.metadata,'isflylightdir',EBAC_DATA.superuser>0,...
    'lineresultsdir',EBAC_DATA.linebehaviordir,...
    'usewebctraxvideo',true,...
    'usewebbehaviorfiles',true,...
    'perlinetext',lineinfostrs);
else
  MakeLineInfoWebpageNoMetadata(EBAC_DATA.nbdata.line_names_curr(inflineidx),'outfilename',filenamecurr,...
    'groupname',groupname,'imdata',EBAC_DATA.nbdata.imdata,'imdata_vnc',EBAC_DATA.nbdata.imdata_vnc,...
    'isflylightdir',EBAC_DATA.superuser>0,...
    'lineresultsdir',EBAC_DATA.linebehaviordir);
end
ClearStatus(handles);
fprintf('Line info webpage: %s was created and should have opened in your browser.\n',filenamecurr);

if clusterid > 0,
  n = sprintf('cluster %d',clusterid);
else
  n = sprintf('SV %d',supervoxelid);
end

if ~isfield(handles,'hfig_showlines') || ~ishandle(handles.hfig_showlines),
  handles.hfig_showlines = figure('Name',sprintf('%s and %s lines',behaviorstring,n));
else
  set(handles.hfig_showlines,'Name',sprintf('%s and %s lines',behaviorstring,n));
  clf(handles.hfig_showlines);
end
if ~isfield(handles,'hfig_showlineaverage') || ~ishandle(handles.hfig_showlineaverage),
  handles.hfig_showlineaverage = figure('Name',sprintf('Average of %s and %s lines',behaviorstring,n));
else
  set(handles.hfig_showlineaverage,'Name',sprintf('Average of %s and %s lines',behaviorstring,n));
  clf(handles.hfig_showlineaverage);
end

SetStatus(handles,'Plotting important lines for %s',n);

[handles.hfig_showlines,handles.hax_showlines,...
  handles.hfig_showlineaverage,handles.hax_showlineaverage] = ...
  PlotImportantLinesForSupervoxels(EBAC_DATA.nbdata.imdata,EBAC_DATA.nbdata.line_names_curr(inflineidx),...
  'hfig_showlines',handles.hfig_showlines,'hfig_showlineaverage',handles.hfig_showlineaverage,...
  'labels',EBAC_DATA.labeldata.labels,'supervoxeldata',EBAC_DATA.bamap.supervoxeldata(inflineidx,:),...
  'SetStatusFcn',@(varargin) SetStatusCallback(hObject,varargin{:}),...
  'anatomydir',EBAC_DATA.anatomydir,'isflylightdir',EBAC_DATA.superuser>0);

for ii = 1:numel(inflineidx),
  i = inflineidx(ii);
  if numel(handles.hax_showlines>=ii) && ishandle(handles.hax_showlines(ii)),
    text(5,5,sprintf('%s: (beh = %.2f) * (anat = %.2f) -> (index = %.2f)',...
      EBAC_DATA.nbdata.line_names_curr{i},...
      EBAC_DATA.bamap.normbehaviordata(i),...
      mean(svdata(i,:)),...
      EBAC_DATA.bamap.normbehaviordata(i)*mean(svdata(i,:))),...
      'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
      'Interpreter','none','Parent',handles.hax_showlines(ii));
  end
  if numel(handles.hax_showlineaverage>=ii) && ishandle(handles.hax_showlineaverage(ii)),
    text(5,5,sprintf('%s: (beh = %.2f) * (anat = %.2f) -> (index = %.2f)',...
      EBAC_DATA.nbdata.line_names_curr{i},...
      EBAC_DATA.bamap.normbehaviordata(i),...
      mean(svdata(i,:)),...
      EBAC_DATA.bamap.normbehaviordata(i)*mean(svdata(i,:))),...
      'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
      'Interpreter','none','Parent',handles.hax_showlineaverage(ii));
  end
end
if numel(handles.hax_showlineaverage>=numel(inflineidx)+1) && ishandle(handles.hax_showlineaverage(numel(inflineidx)+1)),
  text(5,5,'Average expression',...
    'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
    'Interpreter','none','Parent',handles.hax_showlineaverage(numel(inflineidx)+1));
end

ClearStatus(handles);

guidata(hObject,handles);

% --------------------------------------------------------------------
function contextmenu_axes_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;
svinfo = getappdata(handles.him_map,'currentsupervoxel');
if isempty(svinfo),
  set(handles.contextmenu_axes_info,'Label','No supervoxel selected');
  set(handles.contextmenu_axes_showlines,'Enable','off');
else
  supervoxelid = svinfo{1};
  compartment = svinfo{2};
  pvalue = svinfo{3};
  set(handles.contextmenu_axes_showlines,'Enable','on');
  clusterid = 0;
  if strcmpi(handles.datatype,'cluster'),
    clusterid = EBAC_DATA.bamap.clusterres.clusterid(supervoxelid);
  end
  svinfo{5} = clusterid;
  if clusterid > 0,
    set(handles.contextmenu_axes_info,'Label',sprintf('Cluster %d',clusterid));
  else
    set(handles.contextmenu_axes_info,'Label',sprintf('Supervoxel %d in %s, p = %f',supervoxelid,compartment,pvalue));
  end
end
handles.currentsupervoxel = svinfo;
guidata(hObject,handles);

% --------------------------------------------------------------------
function contextmenu_axes_info_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_axes_info (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function contextmenu_axes_show_anotb_lines_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_axes_show_anotb_lines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;

svinfo = handles.currentsupervoxel;
if isempty(svinfo),
  return;
end

supervoxelid = svinfo{1};
% compartment = svinfo{2};
% pvalue = svinfo{3};

if numel(svinfo) > 4,
  clusterid = svinfo{5};
else
  clusterid = 0;
end

%fprintf('Supervoxel %d, cluster %d in %s, p = %f\n',supervoxelid,clusterid,compartment,pvalue);

if clusterid > 0,
  svdata = EBAC_DATA.bamap.supervoxeldata(:,EBAC_DATA.bamap.clusterres.clusterid==clusterid);
  svdata_mu = mean(svdata,2);
  n = sprintf('cluster %d',clusterid);
  n1 = sprintf('cluster%d',clusterid);
else
  svdata = EBAC_DATA.bamap.supervoxeldata(:,supervoxelid);
  svdata_mu = svdata;
  n = sprintf('SV %d',supervoxelid);
  n1 = sprintf('SV%d',supervoxelid);
end

SetStatus(handles,'Finding lines with expression in %s but not behavior...',n);

idx = find(svdata_mu > handles.min_anotb_a & ...
  EBAC_DATA.bamap.normbehaviordata < handles.max_anotb_b);

[order1] = FindImporantLinesForSupervoxels(svdata(idx,:),...
  1-EBAC_DATA.bamap.normbehaviordata(idx));
inflineidx = idx(order1);
if numel(order1) > handles.nlinesshow_anotb,
  inflineidx = inflineidx(1:handles.nlinesshow_anotb);
end

SetStatus(handles,'Creating line info webpage...');
behaviorstring = regexprep(handles.behaviorstring,'\W+','');
filenamecurr = fullfile(tempdir,sprintf('LinesWithAnatomyNotBehavior_%s_%s.html',behaviorstring,n1));
behaviorstring = strtrim(regexprep(handles.behaviorstring,'\W+',' '));
groupname = sprintf('Lines that are not hits for behavior %s but have expression in %s',behaviorstring,n);

[ism,behaviorjs] = ismember(EBAC_DATA.bamap.behaviorfns{1},EBAC_DATA.nbdata.behaviorlabels);
isplus = strcmp(EBAC_DATA.bamap.stattypes{1},'plus');
assert(all(ism));
lineinfostrs = cell(1,numel(inflineidx));
for ii = 1:numel(inflineidx),
  
  linei = inflineidx(ii);
  s = '';
  for jj = 1:numel(behaviorjs),
    j = behaviorjs(jj);
    if isplus(jj),
      s = [s,sprintf('%s_%s = %.3f, ',EBAC_DATA.bamap.behaviorfns{1}{jj},...
        EBAC_DATA.bamap.stattypes{1}{jj},...
        EBAC_DATA.nbdata.normbehaviordata_plus(linei,j))];
    else
      s = [s,sprintf('%s_%s = %.3f, ',EBAC_DATA.bamap.behaviorfns{1}{jj},...
        EBAC_DATA.bamap.stattypes{1}{jj},...
        EBAC_DATA.nbdata.normbehaviordata_minus(linei,j))];
    end
  end
  lineinfostrs{ii} = s(1:end-2);  
end



if isfield(EBAC_DATA.nbdata,'metadata'),
  MakeLineInfoWebpage(EBAC_DATA.nbdata.line_names_curr(inflineidx),'outfilename',filenamecurr,...
    'groupname',groupname,'imdata',EBAC_DATA.nbdata.imdata,'imdata_vnc',EBAC_DATA.nbdata.imdata_vnc,'metadata',EBAC_DATA.nbdata.metadata,...
    'isflylightdir',EBAC_DATA.superuser>0,...
    'lineresultsdir',EBAC_DATA.linebehaviordir,...
    'usewebctraxvideo',true,...
    'usewebbehaviorfiles',true,...
    'perlinetext',lineinfostrs);
else
  MakeLineInfoWebpageNoMetadata(EBAC_DATA.nbdata.line_names_curr(inflineidx),'outfilename',filenamecurr,...
    'groupname',groupname,'imdata',EBAC_DATA.nbdata.imdata,'imdata_vnc',EBAC_DATA.nbdata.imdata_vnc,...
    'isflylightdir',EBAC_DATA.superuser>0,...
    'lineresultsdir',EBAC_DATA.linebehaviordir,...
    'usewebctraxvideo',true);
end  
ClearStatus(handles);
fprintf('Line info webpage: %s was created and should have opened in your browser.\n',filenamecurr);

if ~isfield(handles,'hfig_showlines_anotb') || ~ishandle(handles.hfig_showlines_anotb),
  handles.hfig_showlines_anotb = figure('Name',sprintf('Not %s and %s lines',behaviorstring,n));
else
  set(handles.hfig_showlines_anotb,'Name',sprintf('Not %s and %s lines',behaviorstring,n));
  clf(handles.hfig_showlines_anotb);
end
if ~isfield(handles,'hfig_showlineaverage_anotb') || ~ishandle(handles.hfig_showlineaverage_anotb),
  handles.hfig_showlineaverage_anotb = figure('Name',sprintf('Average of not %s and %s lines',behaviorstring,n));
else
  set(handles.hfig_showlineaverage_anotb,'Name',sprintf('Average of not %s and %s lines',behaviorstring,n));
  clf(handles.hfig_showlineaverage_anotb);
end

SetStatus(handles,'Plotting lines with expression in %s but not behavior...',n);

[handles.hfig_showlines_anotb,handles.hax_showlines,...
  handles.hfig_showlineaverage_anotb,handles.hax_showlineaverage] = ...
  PlotImportantLinesForSupervoxels(EBAC_DATA.nbdata.imdata,EBAC_DATA.nbdata.line_names_curr(inflineidx),...
  'hfig_showlines',handles.hfig_showlines_anotb,'hfig_showlineaverage',handles.hfig_showlineaverage_anotb,...
  'labels',EBAC_DATA.labeldata.labels,'supervoxeldata',EBAC_DATA.bamap.supervoxeldata(inflineidx,:),...
  'SetStatusFcn',@(varargin) SetStatus(handles,varargin{:}),...
  'anatomydir',EBAC_DATA.anatomydir,'isflylightdir',EBAC_DATA.superuser>0);

for ii = 1:numel(inflineidx),
  i = inflineidx(ii);
  if numel(handles.hax_showlines>=ii) && ishandle(handles.hax_showlines(ii)),
    text(5,5,sprintf('%s: (beh = %.2f) * (anat = %.2f) -> (index = %.2f)',...
      EBAC_DATA.nbdata.line_names_curr{i},...
      EBAC_DATA.bamap.normbehaviordata(i),...
      svdata_mu(i),...
      EBAC_DATA.bamap.normbehaviordata(i)*svdata_mu(i)),...
      'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
      'Interpreter','none','Parent',handles.hax_showlines(ii));
  end
  if numel(handles.hax_showlineaverage>=ii) && ishandle(handles.hax_showlineaverage(ii)),
    text(5,5,sprintf('%s: (beh = %.2f) * (anat = %.2f) -> (index = %.2f)',...
      EBAC_DATA.nbdata.line_names_curr{i},...
      EBAC_DATA.bamap.normbehaviordata(i),...
      svdata_mu(i),...
      EBAC_DATA.bamap.normbehaviordata(i)*svdata_mu(i)),...
      'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
      'Interpreter','none','Parent',handles.hax_showlineaverage(ii));
  end
end

if numel(handles.hax_showlineaverage>=numel(inflineidx)+1) && ishandle(handles.hax_showlineaverage(numel(inflineidx)+1)),
  text(5,5,'Average expression',...
    'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
    'Interpreter','none','Parent',handles.hax_showlineaverage(numel(inflineidx)+1));
end

ClearStatus(handles);

guidata(hObject,handles);


% --------------------------------------------------------------------
function contextmenu_axes_map_expr_corr_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_axes_map_expr_corr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;

svinfo = handles.currentsupervoxel;
if isempty(svinfo),
  return;
end

supervoxelid = svinfo{1};
compartment = svinfo{2};
pvalue = svinfo{3};
if numel(svinfo) > 4,
  clusterid = svinfo{5};
else
  clusterid = 0;
end

if clusterid > 0,
  n = sprintf('Cluster %d',clusterid);
  svidx = EBAC_DATA.bamap.clusterres.clusterid==clusterid;
else
  n = sprintf('SV %d',supervoxelid);
  svidx = supervoxelid;
end
% compute correlation in expression between this supervoxel and all others
SetStatus(handles,'Computing correlation to %s...',n);
x = mean(EBAC_DATA.bamap.supervoxeldata(:,svidx),2);
mux = mean(x);
sigx = std(x);
muy = mean(EBAC_DATA.bamap.supervoxeldata,1);
sigy = std(EBAC_DATA.bamap.supervoxeldata,0,1);
corr = (mean(bsxfun(@times,x,EBAC_DATA.bamap.supervoxeldata),1) - mux*muy)./(sigx*sigy);
EBAC_DATA.bamap.exprcorrmap = BehaviorAnatomyMap(corr,EBAC_DATA.labeldata.labels,0);
handles.datatype = 'exprcorr';

fprintf('Supervoxel %d, cluster %d in %s, p = %f\n',supervoxelid,clusterid,compartment,pvalue);

if clusterid > 0,
  s = sprintf('Showing correlation in expression to cluster %d',clusterid);
else
  s = sprintf('Showing correlation in expression to SV %d in %s',supervoxelid,compartment);
end
set(handles.text_map_expr_corr,'Visible','on','String',s);
set(handles.pushbutton_stop_map_expr_corr,'Visible','on');
handles = UpdateMap(handles);
handles = UpdateMaskBoundary(handles);
handles = UpdateMapScaling(handles);
ClearStatus(handles);
guidata(hObject,handles);

% --- Executes on button press in pushbutton_stop_map_expr_corr.
function pushbutton_stop_map_expr_corr_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_stop_map_expr_corr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.text_map_expr_corr,'Visible','off');
set(handles.pushbutton_stop_map_expr_corr,'Visible','off');
handles.datatype = 'pvalue';
handles = UpdateMap(handles);
handles = UpdateMaskBoundary(handles);
handles = UpdateMapScaling(handles);
guidata(hObject,handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global EBAC_DATA; 

try
  rcdata = struct;
  for i = 1:numel(handles.fns_h_rc),
    fn = handles.fns_h_rc{i};
    if isfield(handles,fn),
      rcdata.(fn) = handles.(fn);
    end
  end
  for i = 1:numel(handles.fns_ef_rc),
    fn = handles.fns_ef_rc{i};
    if isprop(EBAC_DATA,fn),
      rcdata.(fn) = EBAC_DATA.(fn);
    end
  end
  for i = 1:numel(handles.fns_e_rc),
    fn = handles.fns_e_rc{i};
    if isprop(EBAC_DATA,fn),
      rcdata.(fn) = EBAC_DATA.(fn);
    end
  end
  rcdata.figpos = get(handles.figure1,'Position');
  save(handles.rcfile,'-struct','rcdata');
  
catch ME
  warning('Error saving rcfile: %s',getReport(ME));
end

clear global EBAC_DATA;
delete(hObject);


% --------------------------------------------------------------------
function menu_edit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_edit_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;

while true,
  if handles.dologcmap,
    colormapsettings = {'log','linear'};
  else
    colormapsettings = {'linear','log'};
  end
  [settingscurr,button] = settingsdlg(...
    'title','Parameters',...
    'description','Set parameters for exploring behavior-anatomy correlations.',...
    'windowposition','center',...
    'WindowWidth',500,...
    'separator','P-value map computation',...
    {'Number of samples';'compute_map_nsamplestotal'},EBAC_DATA.compute_map_nsamplestotal,...
    {'False discovery rate';'compute_map_fdr_alpha'},EBAC_DATA.compute_map_fdr_alpha,...
    'separator','P-value colormapping',...
    {'Colormap interpolation';'dologcmap'},colormapsettings,...
    {'Min. p-value';'minpvalue_log'},handles.minpvalue_log,...
    {'Max. p-value';'maxpvalue'},handles.maxpvalue,...
    'separator','Show important lines for a cluster/supervoxel',...
    {'Frac. behavior/anatomy index to explain';'thresh_ba_explained'},handles.thresh_ba_explained,...
    {'Max. num. lines to show';'maxnlinesshow'},handles.maxnlinesshow,...
    'separator','Show lines with anatomy expression but not behavior',...
    {'Num. lines to show';'nlinesshow_anotb'},handles.nlinesshow_anotb,...
    {'Min. anatomy index','min_anotb_a'},handles.min_anotb_a,...
    {'Max. behavior index','max_anotb_b'},handles.max_anotb_b);
  if ~strcmpi(button,'ok'),
    return;
  end
  
  if ~isnumeric(settingscurr.compute_map_nsamplestotal) || settingscurr.compute_map_nsamplestotal < 0 || ...
      round(settingscurr.compute_map_nsamplestotal) ~= settingscurr.compute_map_nsamplestotal,
    warndlg('Number of samples must be a positive integer','Bad settings value','modal');
    continue;
  end
  
  if ~isnumeric(settingscurr.compute_map_fdr_alpha) || settingscurr.compute_map_fdr_alpha < 0 || ...
      settingscurr.compute_map_fdr_alpha > 1,
    warndlg('False discovery rate must be a number between 0 and 1','Bad settings value','modal');
    continue;
  end

  if ~isnumeric(settingscurr.minpvalue_log) || settingscurr.minpvalue_log <= 0 || settingscurr.minpvalue_log > 1,
    warndlg('Minimum p-value must be between 0 and 1','Bad settings value','modal');
    continue;
  end
  if ~isnumeric(settingscurr.maxpvalue) || settingscurr.maxpvalue < settingscurr.minpvalue_log || settingscurr.maxpvalue > 1,
    warndlg('Maximum p-value must be between minimum p-value and 1','Bad settings value','modal');
    continue;
  end
  if ~isnumeric(settingscurr.thresh_ba_explained) || settingscurr.thresh_ba_explained <= 0 || settingscurr.thresh_ba_explained > 1,
    warndlg('Frac. behavior/anatomy index to explain must be between 0 and 1','Bad settings value','modal');
    continue;
  end
  if ~isnumeric(settingscurr.maxnlinesshow) || settingscurr.maxnlinesshow < 0 || round(settingscurr.maxnlinesshow) ~= settingscurr.maxnlinesshow,
    warndlg('Max. num. lines to show must be a positive integer','Bad settings value','modal');
    continue;
  end
  if ~isnumeric(settingscurr.min_anotb_a) || settingscurr.min_anotb_a <= 0 || settingscurr.min_anotb_a > 1,
    warndlg('Min. anatomy index must be between 0 and 1','Bad settings value','modal');
    continue;
  end
  if ~isnumeric(settingscurr.max_anotb_b) || settingscurr.max_anotb_b < 0 || settingscurr.max_anotb_b >= 1,
    warndlg('Max. behavior index must be between 0 and 1','Bad settings value','modal');
    continue;
  end
  if ~isnumeric(settingscurr.nlinesshow_anotb) || settingscurr.nlinesshow_anotb < 0 || round(settingscurr.nlinesshow_anotb) ~= settingscurr.nlinesshow_anotb,
    warndlg('Num. lines to show must be a positive integer','Bad settings value','modal');
    continue;
  end

  break;
  
end

EBAC_DATA.compute_map_nsamplestotal = settingscurr.compute_map_nsamplestotal;
EBAC_DATA.compute_map_nsamplesperbatch = settingscurr.compute_map_nsamplestotal;
EBAC_DATA.compute_map_fdr_alpha = settingscurr.compute_map_fdr_alpha;

settingscurr.dologcmap = strcmpi(settingscurr.dologcmap,'log');
if settingscurr.dologcmap ~= handles.dologcmap && ~isempty(EBAC_DATA.bamap),
  SetStatus(handles,'Mapping correlations...');
  handles.dologcmap = settingscurr.dologcmap;
  if handles.dologcmap,
    EBAC_DATA.bamap.behaviormap = BehaviorAnatomyMap(max(0,log10(handles.maxpvalue)-log10(EBAC_DATA.bamap.pvalue_fdr)),EBAC_DATA.labeldata.labels,nan);
  else
    EBAC_DATA.bamap.behaviormap = BehaviorAnatomyMap(EBAC_DATA.bamap.pvalue_fdr,EBAC_DATA.labeldata.labels,1);
  end
  ClearStatus(handles);
end

handles.minpvalue_log = settingscurr.minpvalue_log;
handles.maxpvalue = settingscurr.maxpvalue;
handles.minpvalue = handles.minpvalue_log;
if ~isempty(EBAC_DATA.bamap),
  handles = UpdateMap(handles);
  handles = UpdateMapScaling(handles);
end

handles.thresh_ba_explained = settingscurr.thresh_ba_explained;
handles.nlinesshow_anotb = settingscurr.nlinesshow_anotb;
handles.min_anotb_a = settingscurr.min_anotb_a;
handles.max_anotb_b = settingscurr.max_anotb_b;
handles.maxnlinesshow = settingscurr.maxnlinesshow;

guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_analyze_Callback(hObject, eventdata, handles)
% hObject    handle to menu_analyze (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_analyze_clustersv_Callback(hObject, eventdata, handles)
% hObject    handle to menu_analyze_clustersv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.datatype = 'cluster';
handles = ClusterSupervoxels(handles);
set(handles.uipanel_cluster,'Visible','on');
set(handles.uipanel_supervoxel,'Visible','off');
guidata(hObject,handles);


% --- Executes on button press in pushbutton_stop_map_clustering.
function pushbutton_stop_map_clustering_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_stop_map_clustering (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.datatype = 'pvalue';
handles.svmaskid = -1;

set(handles.uipanel_cluster,'Visible','off');
set(handles.uipanel_supervoxel,'Visible','on');

handles = UpdateMap(handles);
handles = UpdateMaskBoundary(handles);
handles = UpdateMapScaling(handles);

guidata(hObject,handles);

% --- Executes on button press in pushbutton_update_clustering.
function pushbutton_update_clustering_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_update_clustering (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = ClusterSupervoxels(handles);
guidata(hObject,handles);

function handles = ClusterSupervoxels(handles)

SetStatus(handles,'Clustering supervoxels into %d groups...',handles.cluster_k);

global EBAC_DATA;

if isfield(EBAC_DATA.bamap,'clusterres'),
  clusterres = EBAC_DATA.bamap.clusterres;
else
  clusterres = struct;
end
  
% cluster
EBAC_DATA.bamap.clusterres = ClusterMapSupervoxels(EBAC_DATA.bamap,handles.cluster_k,...
  'savedata',clusterres,...
  'pvalthresh',handles.cluster_pvalthresh,...
  'behthresh',handles.cluster_behthresh,...
  'anatthresh',handles.cluster_anatthresh);

handles.svmaskid = -1;

% show clustering results
EBAC_DATA.bamap.clustermap = BehaviorAnatomyMap(EBAC_DATA.bamap.clusterres.clusterid,EBAC_DATA.labeldata.labels,0);
nsvs_selected = numel(EBAC_DATA.bamap.clusterres.svidx);
% nlines_selected = nnz(EBAC_DATA.bamap.clusterres.lineidx);
set(handles.text_cluster_nsvs,'String',{'N. supervoxels',['selected: ',num2str(nsvs_selected)]});

handles = UpdateMap(handles);
handles = UpdateMaskBoundary(handles);
handles = UpdateMapScaling(handles);

ClearStatus(handles);


function edit_cluster_k_Callback(hObject, eventdata, handles)
% hObject    handle to edit_cluster_k (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cluster_k as text
%        str2double(get(hObject,'String')) returns contents of edit_cluster_k as a double

v = str2double(get(hObject,'String'));
if isnan(v) || round(v) ~= v || v <= 0,
  warning('Number of clusters must be a positive integer');
  set(hObject,'String',num2str(handles.cluster_k));
  return;
end
handles.cluster_k = v;
guidata(hObject,handles);

function edit_cluster_behthresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_cluster_behthresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cluster_behthresh as text
%        str2double(get(hObject,'String')) returns contents of edit_cluster_behthresh as a double

v = str2double(get(hObject,'String'));
if isnan(v) || v < 0 || v > 1,
  warning('Minimum behavior index must be a number between 0 and 1');
  set(hObject,'String',num2str(handles.cluster_behthresh));
  return;
end
handles.cluster_behthresh = v;
guidata(hObject,handles);

function edit_cluster_anatthresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_cluster_anatthresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cluster_anatthresh as text
%        str2double(get(hObject,'String')) returns contents of edit_cluster_anatthresh as a double

v = str2double(get(hObject,'String'));
if isnan(v) || v < 0 || v > 1,
  warning('Minimum expression must be a number between 0 and 1');
  set(hObject,'String',num2str(handles.cluster_anatthresh));
  return;
end
handles.cluster_anatthresh = v;
guidata(hObject,handles);


function edit_cluster_pvalthresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_cluster_pvalthresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cluster_pvalthresh as text
%        str2double(get(hObject,'String')) returns contents of edit_cluster_pvalthresh as a double

v = str2double(get(hObject,'String'));
if isnan(v) || v < 0 || v > 1,
  warning('Maximum p-value must be a number between 0 and 1');
  set(hObject,'String',num2str(handles.cluster_pvalthresh));
  return;
end
handles.cluster_pvalthresh = v;
guidata(hObject,handles);


% --- Executes during object deletion, before destroying properties.
function contextmenu_axes_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to contextmenu_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function contextmenu_axes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to contextmenu_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --------------------------------------------------------------------
function menu_edit_datalocs_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_datalocs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isstruct(handles) || ~isfield(handles,'sizeinfo'),
  return;
end

set(handles.figure1,'Units','pixels');
newfigpos = get(handles.figure1,'Position');

% minwidth = 800;
% minheight = 500;
minwidth = 400;
minheight = 250;
issmall = false;
if newfigpos(3) < minwidth,
  newfigpos(3) = minwidth;
  issmall = true;
end
if newfigpos(4) < minheight,
  newfigpos(4) = minheight;
  issmall = true;
end

% only shrink widths
if newfigpos(3) < handles.sizeinfo.figure1(3),
  r = newfigpos(3)/handles.sizeinfo.figure1(3);
else
  r = 1;
end

fns = {'uipanel_behavior','uipanel_supervoxel','uipanel_cluster',...
  'text_map_expr_corr','pushbutton_stop_map_expr_corr',...
  'text_showsupervoxelclustering','pushbutton_stop_showsupervoxelclustering',...
};

for i = 1:numel(fns),
  fn = fns{i};
  set(handles.(fn),'Position',handles.sizeinfo.(fn).*[r,1,r,1]);
end

% stretch widths only
r = newfigpos(3)/handles.sizeinfo.figure1(3);
fns = {'edit_z','uipanel_statusbar'};
for i = 1:numel(fns),
  fn = fns{i};
  set(handles.(fn),'Position',handles.sizeinfo.(fn).*[r,1,r,1]);
end

% stretch heights only
r = newfigpos(4)/handles.sizeinfo.figure1(4);
fns = {};
for i = 1:numel(fns),
  fn = fns{i};
  set(handles.(fn),'Position',handles.sizeinfo.(fn).*[1,r,1,r]);
end

% stretch widths and heights
rw = newfigpos(3)/handles.sizeinfo.figure1(3);
rh = newfigpos(4)/handles.sizeinfo.figure1(4);
fns = {'axes_main','slider_z'};
for i = 1:numel(fns),
  fn = fns{i};
  set(handles.(fn),'Position',handles.sizeinfo.(fn).*[rw,rh,rw,rh]);
end

if issmall,
  set(handles.figure1,'Position',newfigpos);
end


% --------------------------------------------------------------------
function menu_file_export_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_file_exit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

figure1_CloseRequestFcn(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menu_file_export_image_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

isstack = false;
switch handles.viewmode,
  case 'maxzprojection',
    viewmodestr = 'maximum projection in z-direction';
    viewmodestr1 = 'maxzprojection';
  case 'maxzsliceprojection',
    viewmodestr = 'maximum projection in z-direction per slice';
    viewmodestr1 = 'maxzsliceprojection';    
  case 'maxyprojection'
    viewmodestr = 'maximum projection in y-direction';
    viewmodestr1 = 'maxyprojection';
  case 'maxysliceprojection',
    viewmodestr = 'maximum projection in y-direction per slice';
    viewmodestr1 = 'maxysliceprojection';    
  case {'xslice','yslice','zslice'},
    viewmodestr = 'image stack';
    viewmodestr1 = 'stack';
    isstack = true;
end

switch handles.datatype,
  
  case 'pvalue'
    datatypestr = 'behavior-anatomy correlation p-value';
    datatypestr1 = 'pvalue';
  case 'cluster'
    datatypestr = sprintf('clustering of supervoxels into %d groups',handles.cluster_k);
    datatypestr1 = sprintf('cluster%d',handles.cluster_k);
  case 'exprcorr'
    svinfo = handles.currentsupervoxel;
    supervoxelid = svinfo{1};
    if numel(svinfo) > 4,
      clusterid = svinfo{5};
    else
      clusterid = 0;
    end
    if clusterid > 0,
      datatypestr = sprintf('expression correlation to cluster %d/%d',clusterid,handles.cluster_k);
      datatypestr1 = sprintf('exprcorr_cluster%dof%d',clusterid,handles.cluster_k);
    else
      datatypestr = sprintf('expression correlation to supervoxel %d',supervoxelid);
      datatypestr1 = sprintf('exprcorr_sv%d',handles.currentsupervoxel{1});      
    end
end

behaviorstr = regexprep(handles.behaviorstring,'[{}]','');
behaviorstr1 = regexprep(behaviorstr,'( AND NOT )|( AND )|( OR )','__$1__');
behaviorstr1 = regexprep(behaviorstr1,'\s','');
if numel(behaviorstr1) > 50,
  behaviorstr1 = behaviorstr1(1:50);
end

SetStatus(handles,'Exporting %s of %s for %s image',viewmodestr,datatypestr,behaviorstr);
if isstack,
  fils = {'.tiff'};
else
  fils = {'.png'};
end

if isfield(handles,'savedir') && exist(handles.savedir,'dir'),
  defaultdir = handles.savedir;
else
  defaultdir = '';
end
defaultfile = fullfile(defaultdir,sprintf('%s_%s_%s%s',behaviorstr1,datatypestr1,viewmodestr1,fils{1}));

[savefilestr,savedir] = uiputfile(fils,sprintf('Save %s of %s for %s image',viewmodestr,datatypestr,behaviorstr),defaultfile);

if ~ischar(savefilestr),
  ClearStatus(handles);
  return;
end

handles.savedir = savedir;
savefile = fullfile(savedir,savefilestr);

cm = colormap(handles.axes_main);
%cm = get(handles.figure1,'Colormap');
clim = get(handles.axes_main,'CLim');

if isstack,

  global EBAC_DATA; %#ok<TLEV>
  for z = 1:handles.zsz,
    switch handles.datatype,
      case 'pvalue',
        im = EBAC_DATA.bamap.behaviormap(:,:,z);
      case 'exprcorr',
        im = EBAC_DATA.bamap.exprcorrmap(:,:,z);
      case 'cluster'
        im = EBAC_DATA.bamap.clustermap(:,:,z);
    end
    rgbim = colormap_image(im,cm,clim);
    
    if z == 1,
      mode = 'overwrite';
    else
      mode = 'append';
    end
    imwrite(rgbim,savefile,'tiff','WriteMode',mode,...
      'Description',sprintf('%s of %s for %s image',viewmodestr,datatypestr,behaviorstr),...
      'Compression','none','Colorspace','rgb');
  end
  
else
  
  im = get(handles.him_map,'CData');

  rgbim = colormap_image(im,cm,clim);
  imwrite(rgbim,savefile,'png',...
    'Description',sprintf('%s of %s for %s image',viewmodestr,datatypestr,behaviorstr),...
    'Compression','none',...
    'CreationTime',datestr(now),...
    'Software','ExploreBehaviorAnatomyCorrelations');
  
end

guidata(hObject,handles);
ClearStatus(handles);

% --------------------------------------------------------------------
function menu_file_export_data_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;

behaviorstr = regexprep(handles.behaviorstring,'[{}]','');
behaviorstr1 = regexprep(behaviorstr,'( AND NOT )|( AND )|( OR )','__$1__');
behaviorstr1 = regexprep(behaviorstr1,'\s','');

SetStatus(handles,'Exporting data for %s',behaviorstr);

if isfield(handles,'savedir') && exist(handles.savedir,'dir'),
  defaultdir = handles.savedir;
else
  defaultdir = '';
end
defaultfile = fullfile(defaultdir,sprintf('%s.mat',behaviorstr1));

[savefilestr,savedir] = uiputfile({'.mat'},sprintf('Save data for %s',behaviorstr),defaultfile);

if ~ischar(savefilestr),
  ClearStatus(handles);
  return;
end

handles.savedir = savedir;
savefile = fullfile(savedir,savefilestr);

savestuff = struct;
savestuff.bamap = EBAC_DATA.bamap;
fnscopy = {'behaviorstring','behavior1','behavior2','logic','more1','more2',...
  'minpvalue_log','maxpvalue','minpvalue','thresh_ba_explained','nlinesshow_anotb',...
  'min_anotb_a','max_anotb_b','maxnlinesshow','cluster_k','cluster_pvalthresh',...
  'cluster_behthresh','cluster_anatthresh'};
for i = 1:numel(fnscopy),
  if isfield(handles,fnscopy{i}),
    savestuff.(fnscopy{i}) = handles.(fnscopy{i});
  end
end
save(savefile,'-struct','savestuff');

guidata(hObject,handles);

ClearStatus(handles);


% --------------------------------------------------------------------
function menu_file_export_all_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_file_export_data_Callback(hObject, eventdata, handles);
menu_file_export_image_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function menu_analyze_showcorrelatedbehaviors_Callback(hObject, eventdata, handles)
% hObject    handle to menu_analyze_showcorrelatedbehaviors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;

x = EBAC_DATA.bamap.normbehaviordata;
mux = nanmean(x);
sigx = nanstd(x);
sigx = max(sigx,eps);
y = [EBAC_DATA.nbdata.normbehaviordata_minus,EBAC_DATA.nbdata.normbehaviordata_plus];
muy = nanmean(y,1);
sigy = nanstd(y,0,1);
sigy = max(sigy,eps);
corr = (nanmean(bsxfun(@times,x,y),1) - mux*muy)./(sigx*sigy);
corr(isnan(corr))=0;

nplot = 100;
[sorted_corr_pos,order_pos] = sort(corr,2,'descend');
i = find(sorted_corr_pos > 0,1,'last');
if isempty(i),
  i = numel(order_pos);
end
ipos = min(i,nplot);

[sorted_corr_neg,order_neg] = sort(-corr,2,'descend');
i = find(sorted_corr_neg > 0,1,'last');
if isempty(i),
  i = numel(order_neg);
end
ineg = min(i,nplot);

nbehaviors = numel(EBAC_DATA.nbdata.behaviorlabels);
behaviorlabels = [cellfun(@(x) [x,'_less'],EBAC_DATA.nbdata.behaviorlabels,'UniformOutput',false)
  cellfun(@(x) [x,'_more'],EBAC_DATA.nbdata.behaviorlabels,'UniformOutput',false)];
behaviorcolors = jet(2*nbehaviors);

if ~isfield(handles,'hfig_showcorrbeh') || ~ishandle(handles.hfig_showcorrbeh),
  handles.hfig_showcorrbeh = figure('Name',sprintf('Behaviors correlated with %s',handles.behaviorstring),...
    'Color',[.2,.2,.2],'InvertHardCopy','off');
  pos = get(handles.figure1,'Position');
  w = min(412,(pos(3)-1)/2);
  pos2 = [pos(1)+(pos(3)-1)/2-w,pos(2),2*w+1,pos(4)];
  set(handles.hfig_showcorrbeh,'Position',pos2);
  drawnow;
else
  set(handles.hfig_showcorrbeh,'Name',sprintf('Behaviors correlated with %s',handles.behaviorstring));
  clf(handles.hfig_showcorrbeh);
end

hax(1) = axes('Position',[.05,.75,.925,.22],'Parent',handles.hfig_showcorrbeh);
hax(2) = axes('Position',[.05,.25,.925,.22],'Parent',handles.hfig_showcorrbeh);

plot(hax(1),1:ipos,corr(order_pos(1:ipos)),'w-');
hold(hax(1),'on');
for ii = 1:ipos,
  i = order_pos(ii);
  plot(hax(1),ii,corr(i),'ko','MarkerFaceColor',behaviorcolors(i,:));
end
set(hax(1),'XTick',1:ipos,'XTickLabel',behaviorlabels(order_pos(1:ipos)));
htickpos = rotateticklabel(hax(1));
for ii = 1:ipos,
  i = order_pos(ii);
  set(htickpos(ii),'Color',behaviorcolors(i,:));
end

title(hax(1),'Positively correlated behaviors','Color','w');
ylabel(hax(1),'Correlation');

plot(hax(2),1:ineg,corr(order_neg(1:ineg)),'w-');
hold(hax(2),'on');
for ii = 1:ineg,
  i = order_neg(ii);
  plot(hax(2),ii,corr(i),'ko','MarkerFaceColor',behaviorcolors(i,:));
end
set(hax(2),'XTick',1:ineg,'XTickLabel',behaviorlabels(order_neg(1:ineg)));
htickneg = rotateticklabel(hax(2));
for ii = 1:ineg,
  i = order_neg(ii);
  set(htickneg(ii),'Color',behaviorcolors(i,:));
end

title(hax(2),'Negatively correlated behaviors','Color','w');
ylabel(hax(2),'Correlation');

set(hax,'Color','k','XColor','w','YColor','w','Box','off');

guidata(hObject,handles);


% --------------------------------------------------------------------
function contextmenu_axes_showcorrbeh_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_axes_showcorrbeh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;

svinfo = handles.currentsupervoxel;
if isempty(svinfo),
  return;
end

nplot = inf;

supervoxelid = svinfo{1};
compartment = svinfo{2};

% note that this is a subset of the behaviors
nbehaviors = numel(EBAC_DATA.nbdata.pvaluedata.behaviorlabels);
pvalues = [EBAC_DATA.nbdata.pvaluedata.pvalue_minus_fdr(supervoxelid,:),...
  EBAC_DATA.nbdata.pvaluedata.pvalue_plus_fdr(supervoxelid,:)];
pvalues(isnan(pvalues)) = inf;
[sorted_pvalues,order] = sort(pvalues);
n = find(sorted_pvalues<handles.maxpvalue,1,'last');
if isempty(n),
  n = numel(pvalues);
end
n = min(n,nplot);

behaviorlabels = [cellfun(@(x) [x,'_less'],EBAC_DATA.nbdata.pvaluedata.behaviorlabels,'UniformOutput',false)
  cellfun(@(x) [x,'_more'],EBAC_DATA.nbdata.pvaluedata.behaviorlabels,'UniformOutput',false)];
behaviorcolors = jet(2*nbehaviors);

figname = sprintf('Behaviors significantly correlated with supervoxel %d in %s',supervoxelid,compartment);

if ~isfield(handles,'hfig_showcorrbeh_sv') || ~ishandle(handles.hfig_showcorrbeh_sv),
  handles.hfig_showcorrbeh_sv = figure('Name',figname,'Color',[.2,.2,.2],'InvertHardCopy','off');
  pos = get(handles.figure1,'Position');
  w = min(412,(pos(3)-1)/2);
  pos2 = [pos(1)+(pos(3)-1)/2-w,pos(2),2*w+1,pos(4)];
  set(handles.hfig_showcorrbeh_sv,'Position',pos2);
  drawnow;
else
  set(handles.hfig_showcorrbeh_sv,'Name',figname);
  clf(handles.hfig_showcorrbeh_sv);
end

hax = axes('Position',[.075,.25,.905,.72],'Parent',handles.hfig_showcorrbeh_sv);

plot(hax,1:n,pvalues(order(1:n)),'w-');
hold(hax,'on');
for ii = 1:n,
  i = order(ii);
  plot(hax,ii,pvalues(i),'ko','MarkerFaceColor',behaviorcolors(i,:));
end
ylim = get(hax,'YLim');
ylim(1) = -ylim(2)/10;
set(hax,'YLim',ylim);
set(hax,'XLim',[-1,n+2]);

set(hax,'XTick',1:n,'XTickLabel',behaviorlabels(order(1:n)));
htick = rotateticklabel(hax(1));
for ii = 1:n,
  i = order(ii);
  set(htick(ii),'Color',behaviorcolors(i,:));
end
ylabel(hax,'P-value');

set(hax,'Color','k','XColor','w','YColor','w','Box','off');

guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_view_maxzsliceprojection_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_maxzsliceprojection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmpi(handles.viewmode,'maxzsliceprojection'),
  return;
end
handles.viewmode = 'maxzsliceprojection';
handles = UpdateView(handles);
handles = UpdateMap(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_view_maxysliceprojection_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_maxysliceprojection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmpi(handles.viewmode,'maxysliceprojection'),
  return;
end
handles.viewmode = 'maxysliceprojection';
handles = UpdateView(handles);
handles = UpdateMap(handles);
guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_edit_findsupervoxel_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_findsupervoxel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;

nsupervoxels = max(EBAC_DATA.labeldata.labels(:));
res = inputdlg(sprintf('Supervoxel ID (number between 1 and %d',nsupervoxels),'Find supervoxel',1);
if isempty(res),
  return;
end

supervoxelid = str2double(res{1});
if isnan(supervoxelid) || supervoxelid < 1 || supervoxelid > nsupervoxels || ...
    round(supervoxelid) ~= supervoxelid,
  warndlg(sprintf('Supervoxel ID must be an integer between 1 and %d',nsupervoxels),'Bad supervoxel id','modal');
  return;
end
% supervoxelid = im(y,x,1);
% if supervoxelid == 0,
%   set(handles.text_supervoxelid,'String','');
%   set(handles.text_compartment,'String','');
%   set(handles.text_pos,'String',sprintf('(%3d,%3d,---)',x,y));
%   set(handles.text_pvalue,'String','');
%   setappdata(handles.him_map,'currentsupervoxel',{});
% else
%   compartmentid = im(y,x,3);
%   compartment = EBAC_DATA.labeldata.maskdata.leg{compartmentid};
%   set(handles.text_supervoxelid,'String',sprintf('%3d',supervoxelid));
%   clusterid = 0;
%   if strcmp(handles.datatype,'cluster') && isfield(EBAC_DATA.bamap,'clusterres'),
%     clusterid = EBAC_DATA.bamap.clusterres.clusterid(supervoxelid);
%   end
%   if clusterid > 0,
%     set(handles.text_label_compartment,'String','Cluster:');
%     set(handles.text_compartment,'String',sprintf('%d (%s)',clusterid,compartment));
%   else
%     set(handles.text_label_compartment,'String','Compartment:');
%     set(handles.text_compartment,'String',compartment);
%   end
%   set(handles.text_pos,'String',sprintf('(%3d,%3d,%3d)',x,y,z));
%   pvalue = EBAC_DATA.bamap.pvalue_fdr(supervoxelid);
%   set(handles.text_pvalue,'String',num2str(pvalue));  
%   setappdata(handles.him_map,'currentsupervoxel',{supervoxelid,compartment,pvalue,[x,y,z],clusterid});
% end
%fprintf('X = %d, Y = %d, C = %d\n',x,y,c);

% try to find in the current view
[xs,ys,zs] = SupervoxelID2CurrentViewPos(handles,supervoxelid);
if isempty(xs),
  % find anywhere in the labels
  [ys,xs,zs] = ind2sub(size(EBAC_DATA.labeldata.labels),find(EBAC_DATA.labeldata.labels == supervoxelid));
  if isempty(ys),
    warndlg(sprintf('Could not find supervoxel ID %d: not sure how this is happening!',supervoxelid),'Supervoxel not found','modal');
    return;
  end
  d = squareform(pdist([xs(:),ys(:),zs(:)]));
  [~,i] = min(sum(d));  
  x = xs(i);
  y = ys(i);
  z = zs(i);
  
  switch handles.viewmode,
    case {'zslice','maxzprojection','maxzsliceprojection'},
      handles.zslice = z;
    case {'yslice','maxyprojection','maxysliceprojection'},
      handles.yslice = y;
  end
  
  % need to switch to a slice view, see if this is ok
  switch handles.viewmode,
    case {'maxzprojection','maxzsliceprojection'}
      res = questdlg('Need to switch to z-slice to find this supervoxel. Ok?');
      if ~strcmpi(res,'Yes'),
        return;
      end
      handles.viewmode = 'zslice';
      handles = UpdateView(handles);
      
    case {'maxyprojection','maxysliceprojection'}
      res = questdlg('Need to switch to y-slice to find this supervoxel. Ok?');
      if ~strcmpi(res,'Yes'),
        return;
      end
      handles.viewmode = 'yslice';
      handles = UpdateView(handles);
  end
  handles = UpdateMap(handles);
else

  d = squareform(pdist([xs(:),ys(:),zs(:)]));
  [~,i] = min(sum(d));
  x = xs(i);
  y = ys(i);
  z = zs(i);
end

[xscreen,yscreen] = ThreeDLoc2ScreenPos(handles,x,y,z);

% make sure selected supervoxel is within view
im = getappdata(handles.him_map,'supervoxelid');
[nr,nc,~] = size(im);
xlim0 = get(handles.axes_main,'XLim');
ylim0 = get(handles.axes_main,'YLim');
xlim = xlim0;
ylim = ylim0;

buffer = 10;
if xscreen-buffer < xlim(1),
  xlim(1) = max(1,xscreen-buffer);
end
if xscreen+buffer > xlim(2),
  xlim(2) = min(nc,xscreen+buffer);
end
if yscreen-buffer < ylim(1),
  ylim(1) = max(1,yscreen-buffer);
end
if yscreen+buffer > ylim(2),
  ylim(2) = min(nr,yscreen+buffer);
end
if any(xlim~=xlim0) || any(ylim~=ylim0),
  set(handles.axes_main,'XLim',xlim,'YLim',ylim);
end

%fprintf('svid = %d: x = %d, y = %d, z = %d\n',supervoxelid,x,y,z);
%fprintf('xscreen = %d, yscreen = %d\n',xscreen,yscreen);

guidata(hObject,handles);
displaySuperVoxelInfo(hObject,[],[xscreen,yscreen],false);
svinfo = getappdata(handles.him_map,'currentsupervoxel');
handles.currentsupervoxel = svinfo;
handles = UpdateMaskBoundary(handles,true,false);


function [xs,ys,zs] = SupervoxelID2CurrentViewPos(handles,supervoxelid)

xs = [];
ys = [];
zs = [];

im = getappdata(handles.him_map,'supervoxelid');
[yscreen,xscreen] = find(im(:,:,1) == supervoxelid);
if isempty(yscreen),
  return;
end
zscreen = im(sub2ind(size(im),yscreen(:),xscreen(:),3+zeros(numel(yscreen),1)));

switch handles.viewmode,
  
  case {'maxzprojection','zslice'}
    
    xs = xscreen;
    ys = yscreen;
    zs = zscreen;
    
  case {'maxyprojection','yslice'},
    
    xs = xscreen;
    zs = yscreen;
    ys = zscreen;
    
  case 'maxzsliceprojection',
    
    xs = xscreen;
    ys = handles.slicey(max(1,min(numel(handles.slicey),round(yscreen))));
    zs = zscreen;
    
  case 'maxysliceprojection'
    
    xs = xscreen;
    zs = handles.slicez(max(1,min(numel(handles.slicez),round(yscreen))));
    ys = yscreen;
    
  case 'xslice',
    warning('Not implemented');
    return;
end


function [xscreen,yscreen] = ThreeDLoc2ScreenPos(handles,x,y,z)

xscreen = [];
yscreen = [];

switch handles.viewmode,
  
  case {'maxzprojection','zslice'}

    xscreen = x;
    yscreen = y;

  case {'maxyprojection','yslice'},
  
    xscreen = x;
    yscreen = z;
    
  case 'xslice',
    warning('Not implemented');
    return;
    
  case 'maxzsliceprojection',
    xscreen = x;
    slicei = find(z >= handles.slice_z0s & z <= handles.slice_z1s,1);
    if ~isempty(slicei),
      yscreen = sub2ind([handles.ysz,handles.nslices],max(1,min(numel(handles.slicey),round(y))),slicei);
    else
      xscreen = [];
    end

  case 'maxysliceprojection',
    xscreen = x;
    slicei = find(y >= handles.slice_y0s & y <= handles.slice_y1s,1);
    if ~isempty(slicei),
      yscreen = sub2ind([handles.zsz,handles.nslices],max(1,min(numel(handles.slicez),round(z))),slicei);
    else
      yscreen = [];
    end

    
  otherwise
    warning('Not implemented');
    return;
    
end

function [x,y,z] = ScreenPos2ThreeDLoc(handles,xscreen,yscreen,zscreen)

x = [];
y = [];
z = [];

switch handles.viewmode,
  
  case {'maxzprojection','zslice'}

    x = xscreen;
    y = yscreen;
    z = zscreen;

  case {'maxyprojection','yslice'},

    x = xscreen;
    z = yscreen;
    y = zscreen;
    
  case 'maxzsliceprojection'
    
    x = xscreen;
    y = handles.slicey(max(1,min(numel(handles.slicey),round(yscreen))));
    z = zscreen;

  case 'maxysliceprojection'
    
    x = xscreen;
    z = handles.slicez(max(1,min(numel(handles.slicez),round(yscreen))));
    y = yscreen;
    
  case 'xslice',
    warning('Not implemented');
    return;
end


% --------------------------------------------------------------------
function contextmenu_axes_show_a_lines_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_axes_show_a_lines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global EBAC_DATA;

svinfo = handles.currentsupervoxel;
if isempty(svinfo),
  return;
end

supervoxelid = svinfo{1};
% compartment = svinfo{2};
% pvalue = svinfo{3};

if numel(svinfo) > 4,
  clusterid = svinfo{5};
else
  clusterid = 0;
end

%fprintf('Supervoxel %d, cluster %d in %s, p = %f\n',supervoxelid,clusterid,compartment,pvalue);

if clusterid > 0,
  svdata = EBAC_DATA.bamap.supervoxeldata(:,EBAC_DATA.bamap.clusterres.clusterid==clusterid);
  svdata_mu = mean(svdata,2);
  n = sprintf('cluster %d',clusterid);
  n1 = sprintf('cluster%d',clusterid);
else
  svdata = EBAC_DATA.bamap.supervoxeldata(:,supervoxelid);
  svdata_mu = svdata;
  n = sprintf('SV %d',supervoxelid);
  n1 = sprintf('SV%d',supervoxelid);
end

SetStatus(handles,'Finding lines with expression in %s...',n);

idx = find(svdata_mu > handles.min_anotb_a);
[~,order1] = sort(svdata_mu(idx),1,'descend');
inflineidx = idx(order1);
if numel(order1) > handles.nlinesshow_anotb,
  inflineidx = inflineidx(1:handles.nlinesshow_anotb);
end

SetStatus(handles,'Creating line info webpage...');
filenamecurr = fullfile(tempdir,sprintf('LinesWithExpression_%s.html',n1));
groupname = sprintf('Lines that have expression in %s',n);
if isfield(EBAC_DATA.nbdata,'metadata'),
  MakeLineInfoWebpage(EBAC_DATA.nbdata.line_names_curr(inflineidx),'outfilename',filenamecurr,...
    'groupname',groupname,'imdata',EBAC_DATA.nbdata.imdata,'imdata_vnc',EBAC_DATA.nbdata.imdata_vnc,'metadata',EBAC_DATA.nbdata.metadata,...
    'isflylightdir',EBAC_DATA.superuser>0,...
    'lineresultsdir',EBAC_DATA.linebehaviordir,...
    'usewebbehaviorfiles',true,...
    'usewebctraxvideo',true);
else
  MakeLineInfoWebpageNoMetadata(EBAC_DATA.nbdata.line_names_curr(inflineidx),'outfilename',filenamecurr,...
    'groupname',groupname,'imdata',EBAC_DATA.nbdata.imdata,'imdata_vnc',EBAC_DATA.nbdata.imdata_vnc,...
    'isflylightdir',EBAC_DATA.superuser>0,...
    'lineresultsdir',EBAC_DATA.linebehaviordir,...
    'usewebctraxvideo',true);
end  
ClearStatus(handles);
fprintf('Line info webpage: %s was created and should have opened in your browser.\n',filenamecurr);

if ~isfield(handles,'hfig_showlines_a') || ~ishandle(handles.hfig_showlines_a),
  handles.hfig_showlines_a = figure('Name',sprintf('%s lines',n));
else
  set(handles.hfig_showlines_a,'Name',sprintf('%s lines',n));
  clf(handles.hfig_showlines_a);
end
if ~isfield(handles,'hfig_showlineaverage_a') || ~ishandle(handles.hfig_showlineaverage_a),
  handles.hfig_showlineaverage_a = figure('Name',sprintf('Average of %s lines',n));
else
  set(handles.hfig_showlineaverage_a,'Name',sprintf('Average of %s lines',n));
  clf(handles.hfig_showlineaverage_a);
end

SetStatus(handles,'Plotting lines with expression in %s...',n);

[handles.hfig_showlines_anotb,handles.hax_showlines,...
  handles.hfig_showlineaverage_anotb,handles.hax_showlineaverage] = ...
  PlotImportantLinesForSupervoxels(EBAC_DATA.nbdata.imdata,EBAC_DATA.nbdata.line_names_curr(inflineidx),...
  'hfig_showlines',handles.hfig_showlines_a,'hfig_showlineaverage',handles.hfig_showlineaverage_a,...
  'labels',EBAC_DATA.labeldata.labels,'supervoxeldata',EBAC_DATA.bamap.supervoxeldata(inflineidx,:),...
  'SetStatusFcn',@(varargin) SetStatus(handles,varargin{:}),...
  'anatomydir',EBAC_DATA.anatomydir,'isflylightdir',EBAC_DATA.superuser>0);

for ii = 1:numel(inflineidx),
  i = inflineidx(ii);
  if numel(handles.hax_showlines>=ii) && ishandle(handles.hax_showlines(ii)),
    text(5,5,sprintf('%s: (beh = %.2f) * (anat = %.2f) -> (index = %.2f)',...
      EBAC_DATA.nbdata.line_names_curr{i},...
      EBAC_DATA.bamap.normbehaviordata(i),...
      svdata_mu(i),...
      EBAC_DATA.bamap.normbehaviordata(i)*svdata_mu(i)),...
      'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
      'Interpreter','none','Parent',handles.hax_showlines(ii));
  end
  if numel(handles.hax_showlineaverage>=ii) && ishandle(handles.hax_showlineaverage(ii)),
    text(5,5,sprintf('%s: (beh = %.2f) * (anat = %.2f) -> (index = %.2f)',...
      EBAC_DATA.nbdata.line_names_curr{i},...
      EBAC_DATA.bamap.normbehaviordata(i),...
      svdata_mu(i),...
      EBAC_DATA.bamap.normbehaviordata(i)*svdata_mu(i)),...
      'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
      'Interpreter','none','Parent',handles.hax_showlineaverage(ii));
  end
end

if numel(handles.hax_showlineaverage>=numel(inflineidx)+1) && ishandle(handles.hax_showlineaverage(numel(inflineidx)+1)),
  text(5,5,'Average expression',...
    'Color','w','HorizontalAlignment','left','VerticalAlignment','top',...
    'Interpreter','none','Parent',handles.hax_showlineaverage(numel(inflineidx)+1));
end

ClearStatus(handles);

guidata(hObject,handles);


% --- Executes on button press in checkbox_advanced.
function checkbox_advanced_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_advanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_advanced
val = get(hObject,'Value');
handles.isadvancedlogic = val == 1;
SetLogicControlVisibility(handles);

guidata(hObject,handles);


function edit_behavior_logicalexpr_Callback(hObject, eventdata, handles)
% hObject    handle to edit_behavior_logicalexpr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_behavior_logicalexpr as text
%        str2double(get(hObject,'String')) returns contents of edit_behavior_logicalexpr as a double

global EBAC_DATA;

cmd = strtrim(get(hObject,'String'));
[success,msgs,parse] = TestLogicParse(cmd,EBAC_DATA.nbdata.behaviorlabels);

if success,
  handles.behaviorstringcurr = cmd;
  handles.parsecurr = parse;
  guidata(hObject,handles);
else
  warndlg(msgs,'Error parsing logic expression');
  if isfield(handles,'behaviorstringcurr'),
    set(hObject,'String',handles.behaviorstringcurr);
  elseif isfield(handles,'behaviorstring'),
    set(hObject,'String',handles.behaviorstring);
  else
    set(hObject,'String','');
  end
  return;
end  


% --- Executes during object creation, after setting all properties.
function edit_behavior_logicalexpr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_behavior_logicalexpr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menu_view_showsupervoxels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_showsupervoxels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set view mode to slice
if ismember(handles.viewmode,{'zslice','yslice'}),
  % nothing to be done
else
  
  res = questdlg('Need to switch to slice view mode to show supervoxels. Ok?');
  if ~strcmpi(res,'Yes'),
    return;
  end  
  if any(handles.viewmode == 'z'),
    % switch to zslice
    handles.viewmode = 'zslice';
  else
    % switch to yslice
    handles.viewmode = 'yslice';
  end
  handles = UpdateView(handles);
end

global EBAC_DATA;

if ~isfield(EBAC_DATA.labeldata,'imcolor'),

  % compute correlation in expression between this supervoxel and all others
  SetStatus(handles,'Computing colored version of supervoxel mapping...');
    
  EBAC_DATA.labeldata.imcolor = zeros([size(EBAC_DATA.labeldata.labels),3],'uint8');
  EBAC_DATA.labeldata.imcolor(EBAC_DATA.labeldata.labels>0) = EBAC_DATA.labeldata.coloring(EBAC_DATA.labeldata.labels(EBAC_DATA.labeldata.labels>0));
  
end

handles.datatype = 'supervoxels';

set(handles.text_showsupervoxelclustering,'Visible','on');
set(handles.pushbutton_stop_showsupervoxelclustering,'Visible','on');

set([handles.menu_view_maxzprojection,handles.menu_view_maxzsliceprojection,...
  handles.menu_view_maxyprojection,handles.menu_view_maxysliceprojection],...
  'Enable','off');

handles = UpdateMap(handles);
handles = UpdateMaskBoundary(handles);
handles = UpdateMapScaling(handles);
ClearStatus(handles);
guidata(hObject,handles);


% --- Executes on button press in pushbutton_stop_showsupervoxelclustering.
function pushbutton_stop_showsupervoxelclustering_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_stop_showsupervoxelclustering (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.text_showsupervoxelclustering,'Visible','off');
set(handles.pushbutton_stop_showsupervoxelclustering,'Visible','off');
set(handles.menu_view_modes,'Enable','on');

handles.datatype = 'pvalue';
handles = UpdateMap(handles);
handles = UpdateMaskBoundary(handles);
handles = UpdateMapScaling(handles);
guidata(hObject,handles);
