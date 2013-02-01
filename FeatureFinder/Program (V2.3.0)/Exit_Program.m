% Exit_Program()
%   This function clears all persistent variables before closing the 
%   window.
%   
%   Input arguments:
%       none
%
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010-2011.

function Exit_Program()

% Retrieve GUI object information
cObjects=vObjects();
Profile_ClearMemory();
vCurrentProfile('clear');

if ~isempty(cObjects.Main)
    delete(cObjects.Main); 
else
    delete(gcf)
end

vLastSelected('clear');
vObjects('clear');
vPaths('clear');
% Util_SortPaths('reset'); commented out for V2.2.0

clear all
