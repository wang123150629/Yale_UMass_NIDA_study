function nFeature=MaxAmpWithTime(nData,Fs,nBL_Range,nTarg_Range)

% Feature description
if nargin==0
    nFeature=['Determines the maximum amplitude in the target window ',...
        'and corresponding time.'];        
    return
end

% Find maximum amplitude in target window
[nMaxAmp nTime]=max(nData(nTarg_Range));

% Determine corresponding time value (in seconds, where sample 1 = time 0)
nTime=(nTime-1)/Fs;

nFeature=[nMaxAmp, nTime];
