% Profile_LoadFilterSettings(PROF,FILTER)
%   This function is used to load the specified filter's settings 
%   from the profile file, and update the GUI accordingly.
%   
%   Input arguments:
%       PROF - the profile name
%       FILTER - the filter for which the settings are to be loaded:  'LP',
%           'HP', 'Notch', or 'all.'
%       
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010-2011.

function Profile_LoadFilterSettings(sWhich)

% Retrieve GUI object information
cObjects=vObjects();

% Exit function if data settings not setup
thisProfile=vCurrentProfile();
if isempty(thisProfile.dataSettings)
    return
end

% Load lowpass filter settings
if strcmpi(sWhich,'all')|strcmpi(sWhich,'LP')
    nOrder=Profile_GetField('FILT_LP_ORDER','to_num');
    nFreq=Profile_GetField('FILT_LP_FREQ','to_num');
    sString=sprintf('(%g%s order, %g Hz)',nOrder,Util_GetSuffix(nOrder),nFreq);
    set(cObjects.FiltSettingsLP,'String',sString)
    nOn=Profile_GetField('FILT_LP','to_num');
    if nOn
        set(cObjects.FiltSettingsLP,'Enable','inactive')
    else
        set(cObjects.FiltSettingsLP,'Enable','off')
    end
end

% Load highpass filter settings
if strcmpi(sWhich,'all')|strcmpi(sWhich,'HP')
    nOrder=Profile_GetField('FILT_HP_ORDER','to_num');
    nFreq=Profile_GetField('FILT_HP_FREQ','to_num');
    sString=sprintf('(%g%s order, %g Hz)',nOrder,Util_GetSuffix(nOrder),nFreq);
    set(cObjects.FiltSettingsHP,'String',sString)
    nOn=Profile_GetField('FILT_HP','to_num');
    if nOn
        set(cObjects.FiltSettingsHP,'Enable','inactive')
    else
        set(cObjects.FiltSettingsHP,'Enable','off')
    end
end
    
% Load notch filter settings
if strcmpi(sWhich,'all')|strcmpi(sWhich,'Notch')
    nOrder=Profile_GetField('FILT_N_ORDER','to_num');
    nFreq1=Profile_GetField('FILT_N_FREQ1','to_num');
    nFreq2=Profile_GetField('FILT_N_FREQ2','to_num');
    sString=sprintf('(%g%s order, %g-%g Hz)',nOrder,Util_GetSuffix(nOrder),nFreq1,nFreq2);
    set(cObjects.FiltSettingsNotch,'String',sString)
    nOn=Profile_GetField('FILT_NOTCH','to_num');
    if nOn
        set(cObjects.FiltSettingsNotch,'Enable','inactive')
    else
        set(cObjects.FiltSettingsNotch,'Enable','off')
    end
end