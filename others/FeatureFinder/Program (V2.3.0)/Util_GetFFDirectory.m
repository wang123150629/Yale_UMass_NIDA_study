function sParDirectory=Util_GetFFDirectory()

sThisFn='FeatureFinder.m';
sParDirectory=which(sThisFn);
for i=1:2
    iSlash=find(sParDirectory=='/'|sParDirectory=='\',1,'last');
    sParDirectory(iSlash:end)=[];
end
