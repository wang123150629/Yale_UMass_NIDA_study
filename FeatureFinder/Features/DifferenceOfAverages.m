function nFeature=DifferenceOfAverages(nData,Fs,nBL_Range,nTarg_Range)

% Feature description
if nargin==0
    nFeature='The difference between the mean amplitudes of the target and baseline windows.';
    return
end

% Compute window amplitudes
nTarg_Amp=mean(nData(nTarg_Range));        
nBL_Amp=mean(nData(nBL_Range));

% Compute difference of averages
nFeature=nTarg_Amp-nBL_Amp;