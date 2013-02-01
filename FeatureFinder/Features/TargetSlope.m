function nFeature=TargetSlope(nData,Fs,nBL_Range,nTarg_Range)

% Feature description
if nargin==0
    nFeature='The slope of the target window.';        
    return
end

% Calculate mean of target window
nTarg_Slope=polyfit([1:length(nTarg_Range)]'./Fs,nData(nTarg_Range),1);        

% Put the feature value in the nFeature variable
nFeature=nTarg_Slope(1);