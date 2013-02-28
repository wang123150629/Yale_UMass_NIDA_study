% [Y_STRING,Y_NUMBER]=Util_FromSeconds(X,DECIMALS,UNIT)
%   This function converts X to the most suitable time units with the 
%   number of decimal spaces specified by DECIMALS.  Users also have the 
%   option of specifying the output UNIT.
%   
%   Inputs:
%       X - The input time (in seconds) to convert
%       DECIMALS - The number of decimal places to include in the output
%       UNIT - The desired output unit (optional)
%           'fs',...,'ms' - femtoseconds to milliseconds
%           's' - seconds
%           'min' - minutes
%           'h' - hours
%           'days' - days
%           'year' - years
%   
%   Outputs:
%       Y_STRING - The output as a string (e.g., '30 m')
%       X_STRING - The output as a number (e.g., 30)
%
% Written by Alex J. Andrews, 2012.

function [sTime,nTime]=Util_FromSeconds(X,nDecimals,sUnit)


% Check input arguments
sTime='';nTime=[];
if nargin<2|nargin>3
    fprintf(['ERROR:  Util_FromSeconds requires two or three input ',...
        'arguments.\n\n'])
    return
elseif ~isnumeric(X)
    fprintf(['ERROR:  The first argument to Util_FromSeconds must ',...
        'be numeric.\n\n']);
    return
elseif ~isnumeric(nDecimals)|nDecimals<0|(round(nDecimals)-nDecimals)~=0
    fprintf(['ERROR:  The number of decimal points must be a positive ',...
        'integer.\n\n']);
    return
end

% Define list of conversions and corresponding time units
sUnits={'fs','ps','ns','us','ms', 's','min','h','days','years'};
nConv=[10^(-15),10^(-12), 10^(-9), 10^(-6), 10^(-3),  1,  60,  60*60,...
    60*60*24,60*60*24*365];

% If desired unit is given, use
if nargin==3
    if ~any(strcmp(sUnits,sUnit))
        fprintf('ERROR:  Bad time unit specified.\n\n');
        return
    else
        nConvFactor=nConv(strcmp(sUnits,sUnit));
        nTime=round(X/(nConvFactor)*(10^nDecimals))/10^nDecimals;
        sTime=sprintf(['%0.',num2str(nDecimals),'f %s'],nTime,sUnit);
    end

% Otherwise, find the largest unit from the above list that is smaller
% than the given number
else
    iUnit=find(abs(X)>nConv,1,'last');
    if isempty(iUnit),iUnit=1;end
    nConvFactor=nConv(iUnit);
    sUnit=sUnits{iUnit};
    nTime=round(X/(nConvFactor)*(10^nDecimals))/10^nDecimals;
    sTime=sprintf(['%0.',num2str(nDecimals),'f %s'],nTime,sUnit);
end
