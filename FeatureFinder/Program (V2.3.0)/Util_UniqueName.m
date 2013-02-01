% UNIQUE=Util_UniqueName(PRE,POST,DIGITS)
%   This function creates a unique filename that begins with PRE, ends
%   with POST, and has a number between.  
%
%   For example, if PRE='C:\Data\File', POST='.txt', and DIGITS=2, then the 
%   first filename to be returned would be C:\Data\File00.txt.  If a file with 
%   this name is then created, this function will return
%   C:\Data\File01.txt the next time it is called with the same input 
%   parameters.
%   
%   Input arguments:
%       PRE - the string used before the counter in the filename, e.g.,
%           'C:\Data\File'
%       POST - the string used after the counter in the filename, e.g.,
%           '.txt'
%       DIGITS - the number of digits to use in the filename counter, e.g.,
%           2
%   
%   Output arguments:
%       UNIQUE - a unique filename, if possible; otherwise the filename
%           with the maximum possible counter.
%
% Written by Alex Andrews, 2010?11.

function sUnique=Util_UniqueName(sPre,sPost,nDigits)

% Loop through each potential name
nMaxInd=(10^nDigits-1);
for iFile=0:nMaxInd
    
    % Construct test name    
    sIndex=sprintf(['%0',num2str(nDigits),'.0f'],iFile);
           
    % Find first name that isn't in use
    sTestName=[sPre,sIndex,sPost];
    fid=fopen(sTestName,'r');
    if fid==-1
        sUnique=sTestName;
        break
    else
        fclose(fid);
    end
    
    % If all names are in use, warn user, and use maximum possible name
    if iFile==nMaxInd
       sUnique=sTestName;
       Comm_Warn('Maximum index reached; duplicate filename created using Util_UniqueName.')
    end    
end

% Ensure that directory exists
warning('off','MATLAB:MKDIR:DirectoryExists')
sPath=fileparts(sUnique);
mkdir(sPath);
warning on all



