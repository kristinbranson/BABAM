function reg_file = GetRegMaxProjFile(imdatacurr)

maxproj_file = imdatacurr.maxproj_file_system_path;
reg_file = regexprep(maxproj_file,'_total.jpg$','.reg.local.jpg');
if ~exist(reg_file,'file'),
  return;
end