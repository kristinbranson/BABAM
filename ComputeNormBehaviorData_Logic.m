function [normbehaviordata,behaviorfns,stattypes] = ComputeNormBehaviorData_Logic(cmd,normbehaviordata_plus,normbehaviordata_minus,behaviorlabels,varargin)

words = regexp(cmd,'((\{\w+\})|(AND)|(OR)|(NOT))','tokens');
words = [words{:}];
N = size(normbehaviordata_plus,1);
normbehaviordata = nan(N,1);
jointype = '';
isnot = false;
behaviorfns = {};
stattypes = {};

for i = 1:numel(words),
  word = words{i};
  switch word,
    case {'AND','OR'}
      jointype = word;
      isnot = false;
    case 'NOT'
      isnot = true;
    otherwise
      m = regexp(word,'^\{(\w+)_((plus)|(minus))\}$','tokens','once');
      fn = m{1};
      behaviortype = m{2};
      fni = find(strcmp(behaviorlabels,fn));
      if numel(fni) ~= 1,
        error('Error matching %s to behaviorlabels',fn);
      end
      if ~ismember(behaviortype,{'plus','minus'}),
        error('Unknown behavior type %s',behaviortype);
      end
      behaviorfns{end+1} = fn; %#ok<AGROW>
      stattypes{end+1} = behaviortype; %#ok<AGROW>
      if strcmp(behaviortype,'plus'),
        x = normbehaviordata_plus(:,fni);
      else
        x = normbehaviordata_minus(:,fni);
      end
      switch jointype,
        case '',
          if isnot,
            error('First argument cannot be NOT');
          end
          normbehaviordata_new = x;
        case 'AND'
          if isnot,
            normbehaviordata_new = max(0,normbehaviordata - x);
          else
            normbehaviordata_new = min(normbehaviordata,x);
          end
        case 'OR',
          if isnot,
            x = 1-x;
          end
          normbehaviordata_new = min(1,normbehaviordata+x);
      end
      normbehaviordata = normbehaviordata_new;
  end
  
end