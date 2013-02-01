% CHANGE=Plot_Change(CHANGE)
%   This function changes the current plot using the input parameter CHANGE
%   and the profile's filelist.
%   
%   Input arguments:
%       CHANGE - the magnitude of change (e.g., CHANGE=-1 will change the
%           current plot to the previous data file in the filelist.
%
%   Output arguments;
%       CHANGE - a boolean value indicating whether plot has been changed.
%
% Written by Alex Andrews, 2010-2012.

function bChange=Plot_Change(nChange)

% Retrieve GUI object information
cObjects=vObjects();

% ------------------------
% -- 1.0 Setup function --
% ------------------------

nMaxPars=6;
bChange=0;

% 1.1 Load the profile's filelist
thisProfile=vCurrentProfile();
cFilelist=thisProfile.fileList;
if isempty(cFilelist)
    return;
end

% ------------------------------------------
% -- 2.0 Determine parameters of new file --
% ------------------------------------------

% 2.1 Get current parameters
cPlotPar=Profile_GetField(cObjects.PlotMenus(:,2),'to_string');

% 2.2 Locate the current file that's loaded
sFilename=Profile_GetFilename(cPlotPar,1);
if ~isempty(sFilename)
    iRow=find(strcmp(cFilelist(:,1),sFilename));
    if isempty(iRow)    
        return
    end
else
    iRow=1; % If file doesn't exist, start over
end

% 2.3 Check whether new selection will be valid, and whether buttons should
% be disabled
iRow=iRow+nChange;
if (iRow<1)||(iRow>size(cFilelist,1))
    Comm_Warn('No further plots.')
    return
elseif size(cFilelist,1)==1
    set(cObjects.PlotButtons{1},'Enable','off');
    set(cObjects.PlotButtons{2},'Enable','off');    
    set(cObjects.PlotButtons{3},'Enable','off');
    set(cObjects.PlotButtons{4},'Enable','off');    
elseif iRow==1
    set(cObjects.PlotButtons{1},'Enable','off');
    set(cObjects.PlotButtons{2},'Enable','on');
    set(cObjects.PlotButtons{3},'Enable','off');
    set(cObjects.PlotButtons{4},'Enable','on');
elseif iRow==size(cFilelist,1)
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

% 2.4 Update index text box
sIndex=sprintf('File: %0.0f/%0.0f',iRow,size(cFilelist,1));
set(cObjects.PlotIndex,'String',sIndex);

% 2.5 Exit function if plot doesn't change
% if nChange==0,return,end
bChange=1;

% 2.6 Determine the parameters of the new file to be loaded
%cNewPars=cell(nMaxPars,1);
cNewPars(1:nMaxPars,1)={''};
temp=cFilelist(iRow,2:end);
cNewPars(1:length(temp))=temp;

% 2.7 If no plot options selected, select raw data
temp=Profile_GetField(cObjects.PlotChecks(:,2),'to_bool');
bShowRaw=temp(1); 
bShowPreview=temp(2); 
if ~bShowRaw&&~bShowPreview
   set(cObjects.PlotChecks{1,1},'Value',1);
   Profile_SaveGUI(cObjects.ProfileMenu);
end

% 2.8 Reset zoom
fLibrary('AxesLim',[]);

% -------------------------
% -- 3.0 Save new values --
% -------------------------

% 3.1 Save new parameters to filelist
Profile_SetField(cObjects.PlotMenus(:,2),cNewPars);

% 3.2 Update drop-down menus
Plot_LoadOptions();

% 3.3 Update last selected variable
Profile_UpdateLastSelected('all');