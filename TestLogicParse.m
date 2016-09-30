function [success,msg,parse] = TestLogicParse(cmd,behaviorlabels)

parse = struct('behaviors',{{}},'mores',{{}},'logics',{{}});
success = false;
msg = '';
helpmsg = {''
  'You should enter a logical expression describing how to '
  'combine behavior statistics. '
  'Example: {backup_plus} AND NOT {jump_plus} AND NOT {stop_minus}. '
  'Specify behavior statistic tests in {braces}, combining a '
  'behavior statistic name (e.g. "backup") and whether to test for an '
  'increase ("plus") or decrease ("minus"). '
  'Examples: {backup_plus}, {jump_plus}, {stop_minus}. '
  'Combine these with logical operators AND or OR. '
  'Specify that a behavior statistic does NOT have an increased or '
  'decreased value with the logical operator NOT.'};

cmd = strtrim(cmd);
if isempty(cmd),
  msg = [{'Empty expression. '};helpmsg];
  return;
end

words = regexp(cmd,'((\{\w+\})|(AND)|(OR)|(NOT))','tokens');
if isempty(words),
  msg = [{'Could not parse logical expression. '};helpmsg];
  return;
end
words = [words{:}];
if isempty(words),
  msg = [{'Could not parse logical expression. '};helpmsg];
  return;
end
jointype = '';
isnot = false;

if ismember(words{1},{'AND','OR','NOT'}),
  msg = [{'First term in expression must be a behavior statistic. '};helpmsg];
  return;
end

for i = 1:numel(words),
  word = words{i};
  switch word,
    case {'AND','OR'}
      jointype = word;
      isnot = false;
      parse.logics{end+1} = jointype;
    case 'NOT'
      isnot = true;
      assert(~isempty(parse.logics));
      parse.logics{end} = [parse.logics{end},' NOT'];
    otherwise
      m = regexp(word,'^\{(\w+)_((plus)|(minus))\}$','tokens','once');
      if isempty(m),
        msg = [{sprintf('Could not parse behavior statistic %s. ',word)};helpmsg];
        return;
      end
      fn = m{1};
      behaviortype = m{2};
      fni = find(strcmp(behaviorlabels,fn));
      parse.behaviors{end+1} = fn;
      if strcmpi(behaviortype,'plus'),
        parse.mores{end+1} = 'More';
      else
        parse.mores{end+1} = 'Less';
      end
      if numel(fni) ~= 1,
        msg = [{sprintf('Error matching %s to behaviorlabels',fn)};helpmsg];
        return;
      end
      if ~ismember(behaviortype,{'plus','minus'}),
        msg = [{sprintf('Unknown behavior type %s (should be plus or minus)',behaviortype)};helpmsg];
        return;
      end
      switch jointype,
        case '',
          if isnot,
            msg = [{'First argument cannot be NOT'};helpmsg];
            return;
          end
        case 'AND'
        case 'OR',
        otherwise
          msg = [{sprintf('Unknown jointype %s. ',jointype)};helpmsg];
          return;
      end
  end
  
end

success = true;