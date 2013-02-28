% Comm_Warn(MSG)
%   This function is used to warn the user of a situation that
%   could lead to unintended results.
%   
%   Input arguments:
%       MSG - the message string
%
%   Output arguments:
%       none
%
% Written by Alex Andrews, 2010-2012.

function Comm_Warn(sMessage)

%Util_PreventInput(false);
h=warndlg(sMessage,'Warning','modal');
waitfor(h);