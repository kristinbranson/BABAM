function behaviormap = BehaviorAnatomyMap(pvalue,labels,padval)

behaviormap = nan(size(labels),'single');
if nargin > 2 && ~isnan(padval),
  behaviormap(:) = padval;
end
behaviormap(labels>0) = pvalue(labels(labels>0));
