% ERR=Profile_Clear()
%   This function clears the current profile and resets all settings to
%   their defaults.
%   
%   Input arguments:
%       none.
%       
%   Output arguments;
%       ERR - error value (true/false) 
%
% Written by Alex Andrews, 2012.

function bError=Profile_Clear()

bError=true;
cObjects=vObjects();

% --------------------------------
% -- 1.0 Delete current profile --
% --------------------------------

% Load profile and get name and sample rate
thisProfile=vCurrentProfile();
sName=thisProfile.name;
Fs=Profile_GetField('FS','to_num');

% Clear current profile and delete; reset "last selected" variable
vCurrentProfile('clear');
thisProfile.deleteMe;
vLastSelected('reset');


% --------------------------
% -- 2.0 Recreate profile --
% --------------------------

% Create profile instance and update
thisProfile=Profile();
thisProfile.name=sName;
vCurrentProfile('set_value',thisProfile);
Profile_SetField('FS',num2str(Fs));

% Select thisProfile in pop-up
cProfiles=get(cObjects.ProfileMenu,'String');
iProfile=find(strcmp(cProfiles,sName));
if isempty(iProfile)||length(iProfile)~=1
    fprintf('ERROR:  Profile not found in drop-down (cmdNewProfile)\n\n');
    return    
end

% Load new profile
set(cObjects.ProfileMenu,'Value',iProfile);
Profile_Load();
Plot_LoadOptions();
Plot_Change(0);
Plot_Data(cObjects.Axes);

bError=false;