function nFeature=TargetMean(nData,Fs,nBL_Range,nTarg_Range)

% Feature description
if nargin==0
    nFeature='The mean of the target window.';        
    return
end

% Calculate mean of target window
nTarg_Amp=mean(nData(nTarg_Range));        

% Put the feature value in the nFeature variable
nFeature=nTarg_Amp;