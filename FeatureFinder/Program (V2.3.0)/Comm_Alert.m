% Comm_Alert(MSG)
%   This function is used to alert the user of new or useful information.
%   
%   Input arguments:
%       MSG - the message string
%
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010-2011.

function Comm_Alert(sMessage)

h=msgbox(sMessage,'Message','help','modal');
waitfor(h);
