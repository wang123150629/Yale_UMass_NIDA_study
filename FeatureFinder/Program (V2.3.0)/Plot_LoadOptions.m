% Plot_LoadOptions()
%   This function retrieves all plot settings for the current profile,
%   and displays them in their respective drop-down menus and checkboxes
%   on the GUI.  The function can also be used to reset the plot section
%   of the GUI, i.e., empty and disable all drop-downs and GUIs.
%   
%   Input arguments:
%       none
%   
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2011.

function Plot_LoadOptions()

sPaths=vPaths();

% Retrieve GUI object information
cObjects=vObjects();
thisProfile=vCurrentProfile();

% ---------------------------
% -- 1.0 General GUI setup -- 
% ---------------------------

% Reset error string
sErrorInfo='';

% If no profile name selected, clear and disable all plot objects
if isempty(thisProfile)|isempty(thisProfile.fileList)|...
        isempty(thisProfile.dataSettings)
    % Clear and disable all checkboxes
    for i=1:length(cObjects.PlotChecks)
        set(cObjects.PlotChecks{i,1},'Value',0) 
        set(cObjects.PlotChecks{i,1},'Enable','off') 
    end    
    % Clear and disable all menus
    for i=1:length(cObjects.PlotMenus)
        set(cObjects.PlotMenus{i,1},'Value',1) 
        set(cObjects.PlotMenus{i,1},'String',{''}) 
        set(cObjects.PlotMenus{i,1},'Enable','off') 
        set(cObjects.PlotMenuTitles{i},'String',{''}) 
    end
    set(cObjects.PlotChan{1,1},'Value',1,'String',{''},'Enable','off');
    set(cObjects.PlotRegion{1,1},'Value',1,'String',{''},'Enable','off');
    % Disable plot buttons
    for i=1:length(cObjects.PlotButtons)
        set(cObjects.PlotButtons{i},'Enable','off')
    end
    % Clear axes
    for i=1:length(cObjects.Axes)
        cla(cObjects.Axes(i));
    end
    
    % Exit function
    return
    
% Otherwise enable all elements
else  
    
    % Clear and enable all checkboxes
    for i=1:length(cObjects.PlotChecks)
        set(cObjects.PlotChecks{i,1},'Value',0) 
        set(cObjects.PlotChecks{i,1},'Enable','on') 
    end
    % Clear and enable all menus
    for i=1:length(cObjects.PlotMenus)
        set(cObjects.PlotMenus{i,1},'Value',1) 
        set(cObjects.PlotMenus{i,1},'String',{''}) 
        set(cObjects.PlotMenus{i,1},'Enable','on')
        set(cObjects.PlotMenuTitles{i},'String',{''}) 
    end
    set(cObjects.PlotChan{1,1},'Value',1,'String',{''},'Enable','on');
    
    % The line below is disabled until region management is brought into
    % the program
    %set(cObjects.PlotRegion{1,1},'Value',1,'String',{''},'Enable','on');
    
    % Enable plot buttons 
    %for i=1:1 % length(cObjects.PlotButtons) (left this up to Plot_Change)
    %   set(cObjects.PlotButtons{i},'Enable','on')
    %end
end


% -----------------------
% -- 2.0 Load filelist --
% -----------------------

% 2.1 Load profile file (assume it's already been verified)
thisProfile=vCurrentProfile();
cFilelist=thisProfile.fileList;
nNumParams=length(thisProfile.parNames);

% -------------------------------
% -- 3.0 Setup parameter menus --
% -------------------------------

% 3.1 Construct cell containing all possible parameter values
for i=1:nNumParams
    % Set parameter titles
    set(cObjects.PlotMenuTitles{i},'String',thisProfile.parNames{i});
    
    % Determine potential values and fill menus
    %cValues=sort(unique(cFilelist.Param(:,i)));
    cValues=Util_AlphaNumSort(unique(cFilelist(:,i+1)));
    cValues=strtrim(cValues);
    set(cObjects.PlotMenus{i,1},'String',cValues);
    
    % Select last used menu items
    %iRow=strcmp(Profile_Settings{1},cObjects.PlotMenus{i,2});
    %sItem=Profile_Settings{2}{iRow};
    sItem=Profile_GetField(cObjects.PlotMenus{i,2},'to_string');
    iMenuItem=find(strcmpi(cValues,sItem));
    
    % If last selected value not available, select first value
    if isempty(iMenuItem)   
        fprintf(['WARNING:  Last setting for ',thisProfile.parNames{i},...
            ' menu not available.  Using first available setting instead.\n\n']);
        set(cObjects.PlotMenus{i,1},'Value',1)
    % Otherwise select last used item
    else
        set(cObjects.PlotMenus{i,1},'Value',iMenuItem)         
    end    
end

% 3.2 Disable all unused menus
for i=nNumParams+1:6
    set(cObjects.PlotMenus{i,1},'Enable','off');
end


% 3.3 Setup channel info
if ~isempty(thisProfile.chanInfo)
    nUsed=thisProfile.chanInfo.toUse;
    cValues=thisProfile.chanInfo.titles(nUsed);  
    set(cObjects.PlotChan{1,1},'String',cValues);
    sChan=Profile_GetField(cObjects.PlotChan{1,2},'to_string');
    
    % If last selected value not available, select first value
    if isempty(sChan)           
        fprintf(['WARNING:  Last setting for channel menu not available.  ',...
            'Using first available setting instead.\n\n']);
        set(cObjects.PlotChan{1,1},'Value',1)
    % Otherwise select last used item
    else
        iMenuItem=find(strcmp(cValues,sChan));
        set(cObjects.PlotChan{1,1},'Value',iMenuItem)         
    end
end

% 3.4 Set last used plot options for checkboxes
% else
    for i=1:length(cObjects.PlotChecks)
        %iRow=strcmp(Profile_Settings{1},cObjects.PlotChecks{i,2});
        %sSetting=Profile_Settings{2}{iRow};
        sSetting=Profile_GetField(cObjects.PlotChecks{i,2},'to_string');
        set(cObjects.PlotChecks{i,1},'Value',str2double(sSetting))
    end
    % Disable secondary checkboxes if necessary, and set value to 0
    if get(cObjects.PlotChecks{2,1},'Value')==0
        set(cObjects.PlotChecks{3,1},'Value',0)
        set(cObjects.PlotChecks{3,1},'Enable','off')
    end
% end

% Call plot loader for last used plot settings

