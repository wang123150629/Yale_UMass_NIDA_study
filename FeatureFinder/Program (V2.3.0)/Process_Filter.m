% FILT=Process_Filter(PROFILE,RAW)
%   This function filters data according to the information stored in
%   PROFILE.
%   
%   Input arguments:
%       PROFILE - the loaded profile
%       RAW - the raw data to be filtered (single channel only)
%
%   Output arguments:
%       FILT - filtered data
%       
% Written by Alex Andrews, 2010-2011.

function nData=Process_Filter(sProfile,nData)


sPaths=vPaths;

% ------------------------------------------------
% -- 1.0 If req., return smoothing filter types --
% ------------------------------------------------

if strcmpi(sProfile,'setup-filters')
    
    % Retrieve all valid filters
    cFilterNames=Process_GetValidFilters();
    
    % Populate filter menu
    if ~isempty(cFilterNames)
        set(nData{1},'String',cFilterNames);
        set(nData{1},'Value',1);
    end
    return
end


% ----------------------------------
% -- 2.0 Retrieve filter settings --
% ----------------------------------

% 2.1 Determine which filters will be used
bLP=Profile_GetField('FILT_LP','to_bool');
bHP=Profile_GetField('FILT_HP','to_bool');
bNotch=Profile_GetField('FILT_NOTCH','to_bool');
sX_Type=Profile_GetField('FILT_X_TYPE','to_string');
if strcmp(sX_Type,'none')
    bX=false;
else
    bX=true;
end

% 2.2 If no filters are specified, exit function; otherwise, find sample rate
if bLP|bHP|bNotch|bX
    Fs=Profile_GetField('FS','to_num');
else
    return
end

% 2.3 Load filter parameters where necessary
if bLP
    nLP_Cutoff=Profile_GetField('FILT_LP_FREQ','to_num');
    nLP_Order=Profile_GetField('FILT_LP_ORDER','to_num');
end
if bHP
    nHP_Cutoff=Profile_GetField('FILT_HP_FREQ','to_num');
    nHP_Order=Profile_GetField('FILT_HP_ORDER','to_num');
end
if bNotch
    nNotch_Cutoff1=Profile_GetField('FILT_N_FREQ1','to_num');
    nNotch_Cutoff2=Profile_GetField('FILT_N_FREQ2','to_num');
    if nNotch_Cutoff1>nNotch_Cutoff2
        temp=nNotch_Cutoff1;
        nNotch_Cutoff1=nNotch_Cutoff2;
        nNotch_Cutoff2=temp;
    end
    nNotch_Order=Profile_GetField('FILT_N_ORDER','to_num');
end


% ---------------------
% -- 3.0 Filter data --
% ---------------------

% 3.1 Create lowpass filter, filter data
if bLP
    nFreq=nLP_Cutoff/(Fs/2);
    if nFreq==0,nFreq=1e-6;end
    if nFreq==1,nFreq=1-1e-6;end
    sError='';
    try
        [b a]=butter(nLP_Order,nFreq,'low');
    catch sError
        fprintf('ERROR:  Low-pass filter unsuccessful!\n');
        nNewLineChars=[0 find(double(sError.message)==10) length(sError.message)+1];
        for i=1:length(nNewLineChars)-1
            fprintf('> %s\n',sError.message((nNewLineChars(i)+1):(nNewLineChars(i+1)-1)));
        end
        fprintf('\n');
    end
    if isempty(sError)
        nData=filter(b,a,nData);
    end
end

% 3.2 Create highpass filter, filter data
if bHP
    nFreq=nHP_Cutoff/(Fs/2);
    if nFreq==0,nFreq=1e-6;end
    if nFreq==1,nFreq=1-1e-6;end    
    sError='';
    try
        [b a]=butter(nHP_Order,nFreq,'high');
    catch sError
        fprintf('ERROR:  High-pass filter unsuccessful!\n');
        nNewLineChars=[0 find(double(sError.message)==10) length(sError.message)+1];
        for i=1:length(nNewLineChars)-1
            fprintf('> %s\n',sError.message((nNewLineChars(i)+1):(nNewLineChars(i+1)-1)));
        end
        fprintf('\n');
    end
    if isempty(sError)
        nData=filter(b,a,nData);
    end       
end

% 3.3 Create notch filter, filter data
if bNotch
    nFreq1=nNotch_Cutoff1/(Fs/2);
    if nFreq1==0,nFreq1=1e-6;end
    if nFreq1==1,nFreq1=1-1e-6;end
    nFreq2=nNotch_Cutoff2/(Fs/2);
    if nFreq2==0,nFreq2=1e-6;end
    if nFreq2==1,nFreq2=1-1e-6;end
    
    sError='';
    try
        [b a]=butter(nNotch_Order,[nFreq1 nFreq2],'stop');
    catch sError
        fprintf('ERROR:  Notch filter unsuccessful!\n');
        nNewLineChars=[0 find(double(sError.message)==10) length(sError.message)+1];
        for i=1:length(nNewLineChars)-1
            fprintf('> %s\n',sError.message((nNewLineChars(i)+1):(nNewLineChars(i+1)-1)));
        end
        fprintf('\n');
    end
    if isempty(sError)
        nData=filter(b,a,nData);
    end         
end

% 3.4 Call external function to filter data
if bX
    [nFilteredData bCrash]=Util_ExternalFcn(sPaths.Filters,sX_Type,...
        {nData,Fs});
    if bCrash|isempty(nFilteredData)|numel(nFilteredData)~=numel(nData)|...
            ~isnumeric(nFilteredData)
        fprintf('ERROR:  ''%s'' filter was unsuccessful.\n\n.',bX_Type);
    else
        nData=nFilteredData;
    end
end


% 3.5 Check signal for NaNs, infinite numers, or imaginary numbers
if any(isnan(nData))
    fprintf(['WARNING:  NaNs were present in filtered data and have ',...
        'been set to 0.\n\n']);
    nData(isnan(nData))=0;
end
if any(abs(nData)==inf)
    fprintf(['WARNING:  Infinite values were present in filtered data and have ',...
        'been set to 0.\n\n']); 
    nData(abs(nData)==inf)=0;
end 
if any(imag(nData))
    nData=real(nData);
    fprintf(['WARNING:  Imaginary components created during filtering; ',...
        'they have been removed.\n\n']);
end


