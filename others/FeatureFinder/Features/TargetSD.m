function nFeature=TargetSD(nData,Fs,nBL_Range,nTarg_Range)

% Feature description
if nargin==0
    nFeature='The standard deviation of the target window.';        
    return
end

% Calculate mean of target window
nTarg_SD=std(nData(nTarg_Range));        

% Put the feature value in the nFeature variable
nFeature=nTarg_SD;