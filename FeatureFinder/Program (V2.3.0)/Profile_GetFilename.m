% FILENAME=Profile_GetFilename(PARS,NOWINDOWS)
%   The role of this function is to return the filename corresponding to a 
%   particular set of parameters.  It either multiple or no filenames 
%   correspond to a given parameter set, then FILENAME will be returned 
%   empty.
%   
%   Input arguments:
%       PARS - a cell array of parameters correpsonding to the filename
%           sought.
%       NOWINDOWS - set to true to supress all possible warning windows
%   
%   Output arguments;
%       FILENAME - one filename corresponding to the given parameter set.
%
% Written by Alex Andrews, 2010?2011.


function sFilename=Profile_GetFilename(cPlotPar,bSuppressWindows)


% Load filelist
thisProfile=vCurrentProfile();
cFilelist=thisProfile.fileList;
cParList=cFilelist(:,2:end);
nNumPars=size(cParList,2);

% Check that cPlotPar is compatible in form with parameter list in cParList
if length(cPlotPar)>nNumPars
    % If parameter set is larger than parameter list, check that excess
    % dimensions aren't used
    for i=nNumPars+1:length(cPlotPar)
        % Warn user and return empty variable if excess dimensions are used
        if ~isempty(cPlotPar{i})
            if ~bSuppressWindows
                Comm_Warn('Requested parameter set doesn''t match profile.');
            end
            sFilename={};
            return
        end
    end
end

% Reset matching variable
bMatch=ones(size(cParList,1),1);

% Loop through each requested parameter
for i=1:nNumPars
    % For each parameter, check which rows correspond to it
    bTheseMatches=strcmp(cParList(:,i),cPlotPar{i});
    bMatch=bMatch&bTheseMatches;
end

% If either multiple or no filenames correspond to a given parameter set,
% then return empty variable and warn user
if sum(bMatch)>1
    if nargin==1|~bSuppressWindows
        Comm_Warn('Multiple filename matches for given parameter set');
    end
    sFilename='';
elseif sum(bMatch)==0
    if nargin==1|~bSuppressWindows
        Comm_Warn('No filenames match given parameter set.');
    end
    sFilename='';
else
    sFilename=cFilelist{bMatch,1};
end

