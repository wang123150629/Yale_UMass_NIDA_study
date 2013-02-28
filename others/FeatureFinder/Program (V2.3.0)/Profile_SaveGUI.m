% Profile_SaveGUI(H_PROF)
%   SaveProfile resaves all profile data to the corresponding profile file.
%   
%   Input arguments:
%       H_PROF - handle to the profile menu
%       
%   Output arguments:
%       none
%
% Written by Alex Andrews, 2010-2011.

function Profile_SaveGUI(hdlProfile)

% Retrieve GUI object information
cObjects=vObjects();

% ---------------------------
% -- 1.0 Load profile file --
% ---------------------------

% Put data from profile object into variable Profile_Settings
cTemp=get(hdlProfile,'String');
nVal=get(hdlProfile,'Value');
if nVal==1
    return
else
    sProfile=cTemp{nVal};
end

% ------------------------------------------
% -- 2.0 Update Profile_Settings variable --
% ------------------------------------------


% 2.1 Enter processing & feature settings into Profile_Settings variable
for iSetting=1:size(cObjects.ProfileDep,1)    
    sObjectType=get(cObjects.ProfileDep{iSetting,1},'type');
    if strcmpi(sObjectType,'uicontrol')
        sElementType=get(cObjects.ProfileDep{iSetting,1},'Style');
        if strcmpi(sElementType,'popupmenu')
            iVal=get(cObjects.ProfileDep{iSetting,1},'Value');
            cVal=get(cObjects.ProfileDep{iSetting,1},'String');
            Profile_SetField(cObjects.ProfileDep{iSetting,2},cVal{iVal});
        elseif strcmpi(sElementType,'checkbox')
            nVal=get(cObjects.ProfileDep{iSetting,1},'Value');
            Profile_SetField(cObjects.ProfileDep{iSetting,2},num2str(nVal));
        elseif strcmpi(sElementType,'edit')
            % NEXT VERSION:  editable profile description
        else
            Comm_Warn('Unexpected element style.');
        end
    end
end

% 2.1b Enter window settings into Profile_Settings variable
nData=get(cObjects.WindowTable{1},'Data');
for iWindow=1:size(cObjects.RangeInfo,1)
   nVal=nData{cObjects.RangeInfo{iWindow,1},cObjects.RangeInfo{iWindow,2}};
   Profile_SetField(cObjects.RangeInfo{iWindow,3},num2str(nVal));    
end

% 2.2 Enter plot settings into Profile_Settings variable
for iSetting=1:size(cObjects.PlotChecks,1)
    nVal=get(cObjects.PlotChecks{iSetting,1},'Value');
    Profile_SetField(cObjects.PlotChecks{iSetting,2},num2str(nVal));    
end

for iSetting=1:size(cObjects.PlotMenus,1)
    iVal=get(cObjects.PlotMenus{iSetting,1},'Value');
    cVal=get(cObjects.PlotMenus{iSetting,1},'String');
    Profile_SetField(cObjects.PlotMenus{iSetting,2},cVal{iVal});
end

%iVal=get(cObjects.PlotRegion{1,1},'Value');
%cVal=get(cObjects.PlotRegion{1,1},'String');
%Profile_SetField(cObjects.PlotRegion{1,2},cVal{iVal});

% Save channel information 
% NOTE:  This must be last, or else settings will be copied from one 
% channel to another)
iVal=get(cObjects.PlotChan{1,1},'Value');
cVal=get(cObjects.PlotChan{1,1},'String');
Profile_SetField(cObjects.PlotChan{1,2},cVal{iVal});


