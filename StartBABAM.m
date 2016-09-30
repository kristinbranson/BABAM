
ebacpath = fileparts(mfilename('fullpath'));
% Initialize all the paths.
addpath(ebacpath);  % in case we ever want to cd out of this dir
baseDir = fileparts(ebacpath);

% put this stuff in the babam directory, no need to mess with paths

% if ~exist('myparse','file'),
%   if exist(fullfile(baseDir,'misc'),'dir'),
%     addpath(fullfile(baseDir,'misc'));
%   else
%     fprintf('Select the "misc" directory.\n');
%     res = uigetdir('.','Select the "misc" directory');
%     if ~ischar(res),
%       return;
%     end
%     if ~exist(res,'dir'),
%       warning('Directory %s does not exist',res);
%       return;
%     else
%       miscdir = res;
%       addpath(miscdir);
%       baseDir = fileparts(miscdir);
%     end
%   end
% end
% if ~exist('get_readframe_fcn','file'),
%   if exist(fullfile(baseDir,'filehandling'),'dir'),
%     addpath(fullfile(baseDir,'filehandling'));
%   else
%     fprintf('Select the "filehandling" directory.\n');
%     res = uigetdir('.','Select the "filehandling" directory');
%     if ~ischar(res),
%       return;
%     end
%     if ~exist(res,'dir'),
%       warning('Directory %s does not exist',res);
%     else
%       filehandlingdir = res;
%       addpath(filehandlingdir);
%     end
%   end
% end

% Start EBAC.
ExploreBehaviorAnatomyCorrelations;
