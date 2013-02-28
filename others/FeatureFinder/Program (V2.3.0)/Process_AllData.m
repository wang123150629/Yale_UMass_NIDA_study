% Process_AllData(PROFILE)
%   This function processes (e.g., normalizes, filters) all data files in
%   the given profile, and then extracts features that are then saved to
%   file.  All processing and feature settings are drawn from the profile
%   settings file.
%   
%   Input arguments:
%       PROFILE - the profile you wish to process
%   
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010-2012. 


function Process_AllData(sProfile)

sPaths=vPaths();
thisProfile=vCurrentProfile();


% ------------------------------------------------------
% -- 1.0 Verify processing options and setup function --
% ------------------------------------------------------

% Get channel information and current channel
nChans=find(thisProfile.chanInfo.toUse);
iOrigChan=thisProfile.getChannel;
cChanNames=thisProfile.chanInfo.titles;

% Loop through each data channel and construct file header with filtering
% info for each channel
sChans='';sFiltLP='';sFiltHP='';sFiltNotch='';sAllFeatTypes='';
sNormalize='';sBLRange='';sTargetRange='';sFiltType='';
sSeparator='  |  '; 
for i=1:length(nChans)

    % Set channel of vCurrentProfile to new chan
    iChan=nChans(i);
    Profile_SetField('PLOT_CHAN',cChanNames{iChan});
    sChans=[sChans,sSeparator,cChanNames{iChan}];

    % 1.1 Pull all processing settings from profile file &
    % prepare descriptive setting strings
    bNormalize(iChan)=Profile_GetField('PRE_NORM','to_bool');
    if bNormalize(iChan)
        sNormalize=[sNormalize,sSeparator,'yes'];
    else
        sNormalize=[sNormalize,sSeparator,'no'];
    end
    
    bFiltNotch=Profile_GetField('FILT_NOTCH','to_bool');
    if ~bFiltNotch
        sFiltNotch=[sFiltNotch,sSeparator,'none'];
    else
        nOrder=Profile_GetField('FILT_N_ORDER','to_num');
        nFreq1=Profile_GetField('FILT_N_FREQ1','to_num');
        nFreq2=Profile_GetField('FILT_N_FREQ2','to_num');
        sFiltNotch=[sFiltNotch,sSeparator,...
            sprintf('%g%s order, %g-%g Hz',nOrder,...
            Util_GetSuffix(nOrder),nFreq1,nFreq2)];    
    end
    
    bFiltLP=Profile_GetField('FILT_LP','to_bool');
    if ~bFiltLP
        sFiltLP=[sFiltLP,sSeparator,'none'];
    else
        nOrder=Profile_GetField('FILT_LP_ORDER','to_num');
        nFreq=Profile_GetField('FILT_LP_FREQ','to_num');
        sFiltLP=[sFiltLP,sSeparator,...          
            sprintf('%g%s order, %g Hz',nOrder,...
            Util_GetSuffix(nOrder),nFreq)];    
    end
    
    bFiltHP=Profile_GetField('FILT_HP','to_bool');
    if ~bFiltHP
        sFiltHP=[sFiltHP,sSeparator,'none'];
    else
        nOrder=Profile_GetField('FILT_HP_ORDER','to_num');
        nFreq=Profile_GetField('FILT_HP_FREQ','to_num');
        sFiltHP=[sFiltHP,sSeparator,...
            sprintf('%g%s order, %g Hz',nOrder,...
            Util_GetSuffix(nOrder),nFreq)];    
    end
        
    sThisFiltType=Profile_GetField('FILT_X_TYPE','to_string');
    sFiltType=[sFiltType,sSeparator,sThisFiltType];
    
    cFeatType{iChan}=Profile_GetField('FEAT_TYPE','to_string'); 
    sAllFeatTypes=[sAllFeatTypes,sSeparator,cFeatType{iChan}];
    
    nBLWindow(iChan,1)=Profile_GetField('FEAT_BL_FROM','to_num');
    nBLWindow(iChan,2)=Profile_GetField('FEAT_BL_TO','to_num');
    sBLRange=[sBLRange,sSeparator,...
        num2str(nBLWindow(iChan,1)),' to ',num2str(nBLWindow(iChan,2)),' s'];
    
    nTargWindow(iChan,1)=Profile_GetField('FEAT_TARG_FROM','to_num');
    nTargWindow(iChan,2)=Profile_GetField('FEAT_TARG_TO','to_num');
    sTargetRange=[sTargetRange,sSeparator,...
        num2str(nTargWindow(iChan,1)),' to ',num2str(nTargWindow(iChan,2)),' s'];
end

Profile_SetField('PLOT_CHAN',cChanNames{iOrigChan});

cFeatureSummary={['  Channels:  ',sChans(length(sSeparator)+1:end)];...
    ['  HP filter:  ',sFiltHP(length(sSeparator)+1:end)];...
    ['  LP filter:  ',sFiltLP(length(sSeparator)+1:end)];...
    ['  Notch filter:  ',sFiltNotch(length(sSeparator)+1:end)];...
    ['  Other filter:  ',sFiltType(length(sSeparator)+1:end)];...
    ['  Normalization:  ',sNormalize(length(sSeparator)+1:end)];...
    ['  Baseline window:  ',sBLRange(length(sSeparator)+1:end)];...
    ['  Target window:  ',sTargetRange(length(sSeparator)+1:end)];...
    ['  Feature:  ',sAllFeatTypes(length(sSeparator)+1:end)]};
    
% 1.2 Display dialog box prompting user to verify their settings
sInput=questdlg({'Please review your settings.','',cFeatureSummary{:},'','Do you wish to proceed?'},...
    'Process Data',...
    'Yes','No','Yes');
if ~strcmp(sInput,'Yes')
    return
end

% 1.3 Generate output filename
sOutfile=Util_UniqueName([sPaths.Results,sProfile,'-Features-',datestr(now,'yymmdd'),'_'],'.txt',2);
[sFileName sPathName]=uiputfile({'*.txt','Text file'},'Create output file',sOutfile);
if all(sFileName==0)|all(sPathName==0)
    %Comm_Warn('No output file selected.  Please try again');
    return
end
sOutfile=[sPathName,sFileName];

% 1.4 Open feature file and write header
cGeneralInfo={['Feature file generated on ',datestr(now,'mmmm dd, yyyy'),' for the profile ''',sProfile,'''']};
fidFeatures=Util_CheckFilename(sOutfile,'w');
if fidFeatures==-1
    Comm_Warn('Feature file could not be created.');
    return
end
fprintf(fidFeatures,'%s\n',cGeneralInfo{:},cFeatureSummary{:});

% 1.5 Update profile file to include name of current output file
Profile_SetField('OUT_FILE',sOutfile);

% 1.6 Get list of raw data files and their sampling rate
cFilelist=thisProfile.fileList;
Fs=Profile_GetField('FS','to_num');


% ------------------------------------
% -- 2.0 Open loop and process data --
% ------------------------------------

% 2.1 Loop through each raw data file, using progress bar
h=waitbar(0,'Extracting features...','WindowStyle','modal');
for iFile=1:size(cFilelist,1)
    % 2.2 Load raw data file
    sRawFilename=cFilelist{iFile,1};
    nData=Data_LoadRaw(sRawFilename);   
    
    if isempty(nData)
        Comm_Warn(['File not found: ',sRawFilename])
        continue
    end
    
    % 2.3 Loop through each data channel
    for i=1:length(nChans)
        
        % Set channel of vCurrentProfile to new chan
        iChan=nChans(i);
        Profile_SetField('PLOT_CHAN',cChanNames{iChan});
        
        
        % 2.4 Filter data, if req.
        nData(:,iChan)=Process_Filter(sProfile,nData(:,iChan));
        
        % 2.5 Normalize data, if req.
        if bNormalize(iChan)
            %nData(:,iChan)=(nData(:,iChan)-mean(nData(:,iChan)))/max(abs(nData(:,iChan)));
            nData(:,iChan)=Process_Normalize(nData(:,iChan),cFilelist(iFile,2:end),[1]);
        end
        
    
    
% -----------------------------------------
% -- 3.0 Extract features and close loop --
% -----------------------------------------
    
        % 3.1 Extract features
        nFeatures=Process_CalcFeatures(sProfile,cFeatType{iChan},nBLWindow(iChan,:),nTargWindow(iChan,:),nData(:,iChan),Fs);
        if isempty(nFeatures),nFeatures=NaN;end

        % 3.2 Write headers if this is the first time through loop
        if iFile==1&i==1
            sPattern=Util_GeneratePattern(length(thisProfile.parNames)+3,'%s','\t','\n');
            cHeader{1}='Raw_Filename';
            cHeader{2}='Channel';
            for i=1:length(thisProfile.parNames),cHeader{i+2}=thisProfile.parNames{i};end
            %cHeader{length(thisProfile.parNames)+3}=sAllFeatTypes(length(sSeparator)+1:end);  individual col headings
            cHeader{length(thisProfile.parNames)+3}='Feature';           
            fprintf(fidFeatures,sPattern,cHeader{:});
        end

        % 3.3 Save features to file
        sPattern=[Util_GeneratePattern(length(thisProfile.parNames)+2,'%s','\t','\t'),...
            Util_GeneratePattern(length(nFeatures),'%e','\t','\n')];    
        fprintf(fidFeatures,sPattern,cFilelist{iFile,1},num2str(iChan),cFilelist{iFile,2:end},nFeatures);
    end
    
    % 3.4 Update progress bar and close loop
    if ~ishandle(h)
        
        % Reset channel to original setting
        Profile_SetField('PLOT_CHAN',cChanNames{iOrigChan});
        
        fclose(fidFeatures);
        Comm_Alert('Processing interrupted!')
        return
    else
        waitbar(iFile/size(cFilelist,1),h)    
    end
end

% Reset channel to orig setting
Profile_SetField('PLOT_CHAN',cChanNames{iOrigChan});
close(h);


% -------------------------
% -- 4.0 "Wrap-up" tasks --
% -------------------------

% 4.1 Close features file
fclose(fidFeatures); 

% 4.2 Alert user of processing progress
Comm_Alert(sprintf('Processing complete!  Please find your data at: %s',sOutfile));


