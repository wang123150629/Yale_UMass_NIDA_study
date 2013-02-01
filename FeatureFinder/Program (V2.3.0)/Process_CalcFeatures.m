% FEATURE=Process_CalcFeatures(PROFILE,TYPE,BL,TARG,DATA,FS)
%   This function extracts a feature specified by TYPE from the data set
%   stored in DATA.  It is also used to fill the feature menu and feature
%   description textbox.
%   
%   Input arguments:
%       PROFILE - name of the profile to which the data belongs
%       TYPE - specified the feature type
%            - to fill the feature menu, use 'fillmenu' as TYPE
%            - to fill the feature description box, use 'SetDesc-' as
%            prefix to feature type, e.g., 'SetDesc-Feature1'
%       BL - baseline window range in seconds, e.g., [0 2]
%       TARG - target window range in seconds, e.g., [2 10]
%       DATA - a matrix containing data from which to extract features
%       FS - sampling rate of the data
%
%   Output arguments;
%       FEATURE - a single feature corresponding to input data OR a boolean
%                 representing error state.
%
%
% Written by Alex Andrews, 2011?2012.

function nFeatures=Process_CalcFeatures(sProfile,sType,nBLWindow,...
    nTargWindow,nData,Fs)

% Prepare output variable
nFeatures=[];
sPaths=vPaths();

% -------------------
% -- 1.0 Setup GUI --
% -------------------

% 1.1 Set required characters for description request
sDesc='SetDesc-';

% 1.2 If requested, fill box under menu with feature description
if strncmp(sProfile,sDesc,8)&&length(sProfile)>length(sDesc)
    sFeature=sProfile(9:end);
    sFeatureDesc=Util_ExternalFcn(sPaths.Features,sFeature);    
    if ~isempty(sFeatureDesc)&ischar(sFeatureDesc)
        set(sType,'String',sFeatureDesc);    
    else
        fprintf(['WARNING:  The %s function did not provide a ',...
            'description.\n\n'],sFeature);
    end
    return    
end

% 1.3 If requested, populate feature menu 
if strcmpi(sProfile,'setup-features')
    % Call function to check for valid features
    cFeatureNames=Process_GetValidFeatures();
    
    % Populate feature menu
    if ~isempty(cFeatureNames)
        set(sType{1},'String',cFeatureNames);
        set(sType{1},'Value',1);
    end
    return
end

% 1.5 If requested, setup window menus 
if strcmpi(sType,'setup-windows')
    nFeatures=false;
    Fs=Profile_GetField('FS','to_num');
    %{
    Still important, but no longer at this point (just when cell edited)
    nMinVal=(Profile_GetField('MIN_WIN_SAMPLES','to_num')-1)/Fs;
    nMaxVal=(Profile_GetField('MAX_WIN_SAMPLES','to_num')-1)/Fs;
    nValRes=Profile_GetField('RES_WIN_TIME','to_num');
    cBL_Vals=nMinVal:nValRes:nMaxVal;
    cTarg_Vals=nMinVal:nValRes:nMaxVal;
    %}

    hHandles=nBLWindow;
    % Populate feature menu
    cFeatureNames=Process_GetValidFeatures();
    if isempty(cFeatureNames)
        nFeatures=true;
        Comm_Warn(['No features available; profile could not be loaded. ',...
            'Check features directory at ',cd,sPaths.Features(3:end)]);
        return 
    end
    set(hHandles{1},'String',cFeatureNames);
    set(hHandles{1},'Value',1);
    % Setup window menus
    %if ~isempty(cBL_Vals)&~isempty(cTarg_Vals)
    %    cBL_Vals=cellfun(@num2str,num2cell(cBL_Vals),'UniformOutput',false);
    %    cTarg_Vals=cellfun(@num2str,num2cell(cTarg_Vals),'UniformOutput',false);
    %    set(hHandles{2},'String',cBL_Vals);set(hHandles{3},'String',cBL_Vals);
    %    set(hHandles{4},'String',cTarg_Vals);set(hHandles{5},'String',cTarg_Vals);  
    %else
    %    fprintf('ERROR:  Can''t setup BL and target drop-downs (Process_CalcFeatures)\n\n');
    %end
    return
end

% 1.6 Calculate conversion factor for windows (currently s to samples)
nConv=Fs;


% ----------------------------
% -- 2.0 Calculate features --
% ----------------------------

% 2.1 Separate time column and data
nTime=[(1:size(nData,1))-1]';
%nTime=nSamples/Fs;

% 2.2 Get baseline information from profile file, convert to indices
temp=round(nBLWindow*nConv); % convert to samples, assuming in ms
nIndex=find(nTime==temp(1));
if ~isempty(nIndex)
    nBL(1)=nIndex; % convert to index
else
    fprintf('WARNING:  Start of baseline window lies outside of data range.\nRounding up to minimum possible time.\n\n');
    nBL(1)=1;
    return
end
nIndex=find(nTime==temp(2));
if ~isempty(nIndex)
    nBL(2)=nIndex; % convert to index
else
    fprintf('ERROR:  End of baseline window lies outside of data range.\n\n');
    return 
end
nBL_Range=nBL(1):nBL(2);

% 2.3 Get target information from profile file, convert to indices
temp=round(nTargWindow*nConv); % convert to samples
nIndex=find(nTime==temp(1));
if ~isempty(nIndex)
    nTarg(1)=nIndex; % convert to index
else
    fprintf('ERROR:  Start of target window lies outside of data range.\n\n');
    return 
end
nIndex=find(nTime==temp(2));
if ~isempty(nIndex)
    nTarg(2)=nIndex; % convert to index
else
    fprintf('WARNING:  End of target window lies outside of data range.\nRounding down to maximum possible time.\n\n');
    nTarg(2)=length(nTime); 
end    
nTarg_Range=nTarg(1):nTarg(2);

% 2.4 Calculate features
[nFeatures bCrash]=Util_ExternalFcn(sPaths.Features,sType,...
    {nData,Fs,nBL_Range,nTarg_Range});

% 2.5 Check value for error
if bCrash|~isnumeric(nFeatures)%|max(size(nFeatures))>1 (commented out for V2.3.0)
    fprintf('ERROR:  Bad "%s" feature generated!\n\n',sType);
elseif isempty(nFeatures)
    fprintf('WARNING:  No value found for "%s" feature.\n\n',sType);
end