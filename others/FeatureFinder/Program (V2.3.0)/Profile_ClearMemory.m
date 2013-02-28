% Profile_ClearMemory()
%   This function calls all functions that use a persistent variable,
%   requesting that these variables are cleared.
%   
%   Input arguments:
%       none
%   
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2011.

function Profile_ClearMemory()

Data_LoadRaw(-1);
% Profile_GetSettings(-1);