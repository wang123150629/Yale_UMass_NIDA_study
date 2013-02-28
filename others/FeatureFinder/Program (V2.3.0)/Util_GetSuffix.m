% SUFFIX=Util_GetSuffix(NUM)
%   This function returns the ordinal number suffix (i.e., 'th', 'st', 
%   'nd', or 'rd') for the given number.
%   
%   Input arguments:
%       NUM - the number for which the ordinal number suffix is requested
%   
%   Output arguments:
%       SUFFIX - the ordinal number suffix, e.g., 'th' or 5, 'nd' for 102
%
% Written by Alex Andrews, 2010?2011.

function sSuffix=Util_GetSuffix(nNum)

% If input argument is not a number or is negative, return empty string
sSuffix='';
if ~isnumeric(nNum)
    fprintf('ERROR:  Input to Util_GetSuffix is not a number.\n\n');
    return
elseif nNum<0
    fprintf('ERROR:  Input to Util_GetSuffix is negative.\n\n');
    return
end

% If a number ends in 0 or 4-9, or is 11, 12, or 13, return 'th'
nLastDig=mod(nNum,10);
if nLastDig==0|(nLastDig>=4&nLastDig<=9)|(nNum>=11&nNum<=13)
    sSuffix='th';
% Otherwise, if a number ends in 1, return 'st'
elseif nLastDig==1
    sSuffix='st';
% Otherwise, if a number ends in 2, return 'nd'
elseif nLastDig==2
    sSuffix='nd';
% Otherwise, if a number ends in 3, return 'rd'
elseif nLastDig==3
    sSuffix='rd';
end

