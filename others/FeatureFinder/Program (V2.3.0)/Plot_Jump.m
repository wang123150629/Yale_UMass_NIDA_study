% Plot_Jump(INDEX)
%   This function changes the current plot in the profile file to that with 
%   the provided parameters or index.
%   
%   Input arguments:
%       INDEX - an integer specifying the row of the given filename in the
%       filenames file (-1 means last).
%
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010?2011.

function Plot_Jump(nIndex)

cObjects=vObjects();

% ------------------------
% -- 1.0 Setup function --
% ------------------------

nMaxPars=6;

% 1.1 Load the profile's filelist
thisProfile=vCurrentProfile();
cFilelist=thisProfile.fileList;
if isempty(cFilelist)
    return;
end

% 1.2 Make sure provided index is valid
if (nIndex<0||nIndex>size(cFilelist,1))&&(nIndex~=-1)
    return

% 1.3 If last file requested, determine index
elseif nIndex==-1
    nIndex=size(cFilelist,1);
end


% ------------------------------------------
% -- 2.0 Determine parameters of new file --
% ------------------------------------------

% 2.1 Check whether new selection will be valid, and whether buttons should
% be disabled
if (nIndex<1)||(nIndex>size(cFilelist,1))
    Comm_Warn('No further plots.')
    return
elseif nIndex==1
    set(cObjects.PlotButtons{1},'Enable','off');
    set(cObjects.PlotButtons{2},'Enable','on');
    set(cObjects.PlotButtons{3},'Enable','off');
    set(cObjects.PlotButtons{4},'Enable','on');
elseif nIndex==size(cFilelist,1)
    set(cObjects.PlotButtons{1},'Enable','on');
    set(cObjects.PlotButtons{2},'Enable','off');
    set(cObjects.PlotButtons{3},'Enable','on');
    set(cObjects.PlotButtons{4},'Enable','off');
else
    set(cObjects.PlotButtons{1},'Enable','on');
    set(cObjects.PlotButtons{2},'Enable','on');    
    set(cObjects.PlotButtons{3},'Enable','on');
    set(cObjects.PlotButtons{4},'Enable','on');
end

% 2.2 Update index text box
sIndex=sprintf('File: %0.0f/%0.0f',nIndex,size(cFilelist,1));
set(cObjects.PlotIndex,'String',sIndex);

% 2.3 Determine the parameters of the new file to be loaded
%cNewPars=cell(nMaxPars,1);
cNewPars(1:nMaxPars,1)={''};
temp=cFilelist(nIndex,2:end);
cNewPars(1:length(temp))=temp;


% -------------------------
% -- 3.0 Save new values --
% -------------------------

% 3.1 Save new parameters to filelist
Profile_SetField(cObjects.PlotMenus(:,2),cNewPars);

% 3.2 Update drop-down menus
Plot_LoadOptions();

% 3.3 Update last selected variable
Profile_UpdateLastSelected('all');