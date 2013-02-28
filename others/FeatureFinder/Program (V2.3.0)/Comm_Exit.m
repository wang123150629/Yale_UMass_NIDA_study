% Comm_Exit()
%   This function confirms that the user wishes to exit the program.
%   
%   Input arguments:
%       MSG - the message string
%
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010?2011.

function Comm_Exit()

% Verify that the user wishes to exist
sInput=questdlg('Are you sure you wish to exit?','Verify exit',...
    'Exit','Stay','Stay');
if strcmpi(sInput,'exit')
    Exit_Program();
end