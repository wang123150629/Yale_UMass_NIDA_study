function nFeature=TargetMax(nData,Fs,nBL_Range,nTarg_Range)

% Feature description
if nargin==0
    nFeature='The max of the target window.';        
    return
end

% Calculate max of target window
nTarg_Amp=max(nData(nTarg_Range));        

% Put the feature value in the nFeature variable
nFeature=nTarg_Amp;