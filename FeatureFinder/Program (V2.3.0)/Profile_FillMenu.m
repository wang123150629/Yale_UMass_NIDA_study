% ERR=Profile_FillMenu(H_MENU,PATHNAME)
%   This function searches PATHNAME for profile files, and then enters
%   all profiles into the menu specified by H_MENU.
%   
%   Input arguments:
%       H_MENU - the handle for the profile menu
%       PATHNAME - the path containing profile files.
%   
%   Output arguments;
%       ERR - contains information in case of error
%
% Written by Alex Andrews, 2011.

function sErrorInfo=Profile_FillMenu(hdlMenu,sPathname)

sErrorInfo='';

% Retrieve list of valid profile files
cProfileNames=Profile.getProfileNames(sPathname,'this_version');
if isempty(cProfileNames)
    cProfileNames={'Select...'};
    % Alert user if no files found
    % Comm_Warn('No profiles found in profile directory!');    
else
    cProfileNames=['Select...',cProfileNames];
end

% Fill menu
set(hdlMenu,'Value',1);
set(hdlMenu,'String',cProfileNames);