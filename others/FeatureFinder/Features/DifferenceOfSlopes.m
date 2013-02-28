function nFeature=DifferenceOfSlopes(nData,Fs,nBL_Range,nTarg_Range)

% Feature description
if nargin==0
    nFeature='The difference between the slopes of the target and baseline windows.';        
    return
end

% Calculate mean of target window
nBL_Slope=polyfit([1:length(nBL_Range)]'./Fs,nData(nBL_Range),1);
nTarg_Slope=polyfit([1:length(nTarg_Range)]'./Fs,nData(nTarg_Range),1);        

% Put the feature value in the nFeature variable
nFeature=nTarg_Slope(1)-nBL_Slope(1);