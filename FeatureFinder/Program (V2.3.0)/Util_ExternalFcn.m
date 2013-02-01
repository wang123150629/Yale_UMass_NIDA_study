% [OUT CRASH]=Util_ExternalFcn(PATH,FUNCTION,ARGS)
%   This function calls the specified function that exists in the given
%   path.  (It is a convenience function.)
%   
%   Input arguments:
%       PATH - The path at which the given function can be found
%       FUNCTION - The function to execute
%       ARGS - Input arguments for the given function, housed in a cell
%
%   Output arguments;
%       OUT - Output arguments from the called function
%       CRASH - Boolean variable representing crash state
%
% Written by Alex Andrews, 2011.

function [vargout bCrash]=Util_ExternalFcn(sPath,sFunction,cArgs)

vargout=[];
bCrash=false;

% Create calling string
sCallingString=[sFunction,'('];
if nargin==3
    for i=1:length(cArgs)
        sCallingString=[sCallingString,'cArgs{',num2str(i),'},'];
    end
    sCallingString(end)=')';
elseif nargin==2
    sCallingString(end+1)=')';
else
    fprintf('ERROR:  Bad number of input arguments to Util_ExternalFcn.\n\n');
    return
end

% Check that function exists
if sPath(end)=='/'|sPath(end)=='\'
   sPath(end)=[]; 
end
if ~exist([sPath,'/',sFunction,'.m'],'file')&...
        ~exist([sPath,'/',sFunction,'.p'],'file')
    fprintf('ERROR:  Function does not exist at specified path (Util_ExternalFcn).\n\n');
    return
end

% Change path and try to execute function
sCurrentPath=cd;
try
    cd(sPath);    
    vargout=eval(sCallingString);
catch sError
    fprintf('   ERROR:  Error calling %s from %s.\n',sFunction,sPath);
    nNewLineChars=[0 find(double(sError.message)==10) length(sError.message)+1];
    for i=1:length(nNewLineChars)-1
        fprintf('        > %s\n',sError.message((nNewLineChars(i)+1):(nNewLineChars(i+1)-1)));
    end
    fprintf('\n');
    bCrash=true;
end

% Change path back
cd(sCurrentPath);