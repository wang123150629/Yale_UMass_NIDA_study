% Comm_Help(MSG)
%   This function displays MSG to the user in a help dialog box.
%   
%   Input arguments:
%       MSG - the message string
%
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010-2012.

function Comm_Help(sTitle,sMessage)

%Util_PreventInput(false);
h=msgbox(sMessage,sTitle,'help','modal');
waitfor(h);