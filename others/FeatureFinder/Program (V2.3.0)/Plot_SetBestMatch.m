% CHANGED=Plot_SetBestMatch(COLUMN)
%   This function determines whether the current drop-down values
%   correspond to a file in the filelist.  If they don't, the selection that
%   matches the greatest number of parameters, with importance given to the
%   left-most parameters, is set.  The new parameter set must contain the
%   most recently selected drop-down (specified by COLUMN).
%   
%   Input arguments:
%       COLUMN - The most recently selected parameter.
%
%   Output arguments;
%       CHANGED - A boolean argument indicating whether the function
%           changed the current plot.
%
% Written by Alex Andrews, 2011.

function bChanged=Plot_SetBestMatch(iLastColSelected)


% Retrieve GUI object information
cObjects=vObjects();

% Load filelist
thisProfile=vCurrentProfile();
cFilelist=thisProfile.fileList;

bChanged=false;

% -------------------------------
% -- 1.0 Load necessary values -- 
% -------------------------------

% 1.1 Load valid parameter list
cParList=cFilelist(:,2:end);
nNumPars=size(cParList,2);

% 1.2 Determine current drop-down selection
cNewPlotPar=Profile_GetField(cObjects.PlotMenus(:,2),'to_string');
cNewPlotPar=cNewPlotPar(1:nNumPars)';    

% -------------------------
% -- 2.0 Find best match --
% -------------------------

% 2.1 Determine how well the new parameter list matches with each file
bMatches=zeros(size(cParList,1),size(cParList,2));
for i=1:size(cParList,1)
    if strcmp(cParList{i,iLastColSelected},cNewPlotPar{iLastColSelected})           
        bMatches(i,:)=strcmp(cParList(i,:),cNewPlotPar);
    end
end

% 2.2 Determine most number of parameters matched (if there is a complete
%     match, return)
nMostParMatches=max(sum(bMatches,2));
if nMostParMatches==nNumPars
    return
else
    bChanged=true;
end

% 2.3 Sort results and determine best match
[nSortMatch,iSortMatch]=sortrows(bMatches);
nBestParMatches=nSortMatch(end,:);
for i=1:length(nSortMatch)
    if isequal(nBestParMatches,nSortMatch(i,:))
        iBestMatch=iSortMatch(i);
        % nBestMatch=cParList(iBestMatch,:);    
        break 
    end
end

% ------------------------
% -- 3.0 Set best match --
% ------------------------

Plot_Jump(iBestMatch);