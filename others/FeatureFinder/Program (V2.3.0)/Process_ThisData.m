% [DATA TIME FEATURES FEATURENAME]=Process_ThisData(RAWDATA,RAWSAMPLES,FS)
%   This function processes (e.g., normalizes, filters) the inputted data 
%   file, and then extracts features.  All processing and feature settings 
%   are drawn from the profile settings file.  The processed data and 
%   features are returned by the function.
%   
%   Input arguments:
%       RAWDATA - the raw data file to process
%       RAWSAMPLES - the sample numbers corresponding to the raw data file
%       FS - the sampling rate of the inputted data file
%   
%   Output arguments:
%       DATA - the processed data
%       TIME - the time variable for the processed data
%       FEATURES - features calculated for the processed data
%       FEATURENAME - the name of the calculated feature
%
% Written by Alex Andrews, 2010-2011.  


function [nProcData nProcTime nFeatures sFeatType]=...
    Process_ThisData(nRawData,nRawSamples,Fs)

% Retrieve GUI object information
cObjects=vObjects();
thisProfile=vCurrentProfile();
sProfile=thisProfile.name;

% ------------------------------------------------------
% -- 1.0 Verify processing options and setup function --
% ------------------------------------------------------

% 1.1 Pull all processing settings from profile file
bNormalize=Profile_GetField('PRE_NORM','to_bool');
sFeatType=Profile_GetField('FEAT_TYPE','to_string');    
nFeatDelim=Profile_GetField('FEAT_DELIM','to_num');
nBLWindow(1)=Profile_GetField('FEAT_BL_FROM','to_num');
nBLWindow(2)=Profile_GetField('FEAT_BL_TO','to_num');
nTargWindow(1)=Profile_GetField('FEAT_TARG_FROM','to_num');
nTargWindow(2)=Profile_GetField('FEAT_TARG_TO','to_num');
cPlotPar=Profile_GetField(cObjects.PlotMenus(:,2),'to_string');
nNormParams=[1];


% ----------------------
% -- 2.0 Process data --
% ----------------------

% 2.1 Loop through each data channel
nProcData=nRawData;
for iChan=1:size(nRawData,2) 
    
    % 2.2 Filter data, if req.
    nProcData(:,iChan)=Process_Filter(sProfile,nProcData(:,iChan));
    
    % 2.3 Normalize data, if req.
    if bNormalize
        temp=Process_Normalize(nProcData(:,iChan),cPlotPar,nNormParams);
        if ~isempty(temp)
            nProcData(:,iChan)=temp;
        else
            Profile_SetField('PRE_NORM','0');            
            bNormalize=0;
            iNorm=strcmp(cObjects.ProfileDep(:,2),'PRE_NORM');
            set(cObjects.ProfileDep{iNorm,1},'Value',0)
        end
    end
end
nProcTime=(nRawSamples-1)/Fs;


% -----------------------------------------
% -- 3.0 Extract features and close loop --
% -----------------------------------------
    
% 3.1 Extract features 
nFeatures=Process_CalcFeatures(sProfile,sFeatType,nBLWindow,nTargWindow,nProcData,Fs);
if isempty(nFeatures)
   return
end    

