% SORTED=Util_SortPaths(RETURN)
%   The Util_SortPaths function checks the path list of the user's MATLAB
%   installation, and if paths exist that aren't based in the MATLAB root,
%   they are moved to the bottom of the list.  (Confirmation from the user 
%   is required for the path rearrangement.)  This function was integrated 
%   into the program after discovering the UITABLE errors caused by the MIR 
%   toolbox.
%   
%   Input arguments:
%       RETURN - if 'reset', the function resets MATLAB's path
%           list to its original value
%
%   Output values:
%       SORTED - a boolean value representing whether the path list was
%           resorted.
%
% Written by Alex Andrews, 2011.

function bSorted=Util_SortPaths(sReturn)

persistent sPath

bSorted=false;

% If requested, return MATLAB path list to its original value
if nargin>1
    fprintf('ERROR:  Bad number of input arguments to Util_SortPaths.\n\n');
    return
elseif nargin==1
    if strcmp(sReturn,'reset')
        if ~isempty(sPath)
            path(sPath);
            clear sPath
        else
            fprintf('WARNING:  Original path list could not be reset.\n\n')            
        end
    else  
        fprintf('ERROR:  Bad input argument to Util_SortPaths.\n\n');
    end
    return    
end

% Read in path list from user's computer
sPath=path;
sPathSep=pathsep;
iPathSep=find(sPath==sPathSep);
nNumPaths=length(iPathSep)+1;
cPaths=cell(nNumPaths,1);
cPaths{1}=sPath(1:iPathSep(1)-1);
for i=1:nNumPaths-2
    cPaths{i+1}=sPath(iPathSep(i)+1:iPathSep(i+1)-1);
end
cPaths{nNumPaths}=sPath(iPathSep(end)+1:end);

% Determine position of all directories not based in the MATLAB root
sRoot=matlabroot;
bNotInRoot=true(nNumPaths,1);
for i=1:nNumPaths
    if strcmp(sRoot,cPaths{i}(1:min(length(cPaths{i}),length(sRoot))))
        bNotInRoot(i)=false;        
    end
end

% Prompt user to verify change in path list
if any(bNotInRoot~=sort(bNotInRoot))
    sInput=questdlg(['The MATLAB path list gives precedence to some ',...
        'paths that do not lie in the MATLAB root.  This may cause ',...
        'errors in MATLAB''s normal function. ',...
        'Do you give FeatureFinder permission to rearrange the list?'],...
        'Path issue',...
        'Yes','Yes, temporarily','No','Yes');
    if ~(strcmpi(sInput,'Yes')|strcmpi(sInput,'Yes, temporarily'))
        return
    end  
    
% Change path list
    [~,iSorted]=sort(bNotInRoot);
    cPaths=cPaths(iSorted);
    sNewPath=cPaths{1};
    for i=2:length(cPaths)
       sNewPath=[sNewPath,sPathSep,cPaths{i}];
    end
    path(sNewPath);
    bSorted=true;
    
% If 'Yes', selected reset original path to new path
    if strcmpi(sInput,'Yes')
        sPath=sNewPath;
    end

end