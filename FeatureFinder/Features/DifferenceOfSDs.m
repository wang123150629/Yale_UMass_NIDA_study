function nFeature=DifferenceOfSDs(nData,Fs,nBL_Range,nTarg_Range)

% Feature description
if nargin==0
    nFeature='The difference between the standard deviations of the target and baseline windows.';        
    return
end

% Calculate mean of target window
nBL_SD=std(nData(nBL_Range));
nTarg_SD=std(nData(nTarg_Range));        

% Put the feature value in the nFeature variable
nFeature=nTarg_SD-nBL_SD;