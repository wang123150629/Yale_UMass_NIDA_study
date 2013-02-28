% [Y_STRING,Y_NUMBER]=Util_ToEngNotation(X,DECIMALS,PREFIX)
%   This function returns X in engineering notation with the specified
%   number of DECIMALS.  The user may also enter a PREFIX (such as k, M, or
%   u) if they wish the output to use that format.  For example, the
%   program would return ['12.3 m',12.3] for the function call 
%   Util_ToEngNotation(0.012342,1)
%   
%   Inputs:
%       X - The input number to convert to engineering notation
%       DECIMALS - The number of decimal places to include in the output
%       PREFIX - The desired prefix for the output (optional)
%   
%   Outputs:
%       Y_STRING - The output as a string (e.g., '12.3 m')
%       X_STRING - The output as a number (e.g., 12.3)
%
% Written by Alex J. Andrews, 2012.

function [sEng,nEng]=Util_ToEngNotation(X,nDecimals,sPrefix)

% Check input arguments
sEng='';nEng=[];
if nargin<2|nargin>3
    fprintf(['ERROR:  Util_ToEngNotation requires two or three input ',...
        'arguments.\n\n'])
    return
elseif ~isnumeric(X)
    fprintf(['ERROR:  The first argument to Util_ToEngNotation must ',...
        'be numeric.\n\n']);
    return
elseif ~isnumeric(nDecimals)|nDecimals<0|(round(nDecimals)-nDecimals)~=0
    fprintf(['ERROR:  The number of decimal points must be a positive ',...
        'number.\n\n']);
    return
end

% Define list of exponents and corresponding SI prefixes
sExponents={'f','p','n','u','m', '','k','M','G','T','P'};
nExponents=[-15,-12, -9, -6, -3,  0,  3,  6,  9, 12, 15];

% If desired SI prefix is given, use
if nargin==3
    if ~any(strcmp(sExponents,sPrefix))
        fprintf('ERROR:  Bad SI prefix specified.\n\n');
        return
    else
        nExponent=nExponents(strcmp(sExponents,sPrefix));
        nEng=round(X/(10^nExponent)*(10^nDecimals))/10^nDecimals;
        sEng=sprintf(['%0.',num2str(nDecimals),'f %s'],nEng,sPrefix);
    end

% Otherwise, find the largest exponent from the above list that is smaller
% than the given number
else
    iExp=find(nExponents<log10(X),1,'last');
    if isempty(iExp),iExp=1;end
    nExp=nExponents(iExp);
    sPrefix=sExponents{iExp};
    nEng=round(X/(10^nExp)*(10^nDecimals))/10^nDecimals;
    sEng=sprintf(['%0.',num2str(nDecimals),'f %s'],nEng,sPrefix);
end
