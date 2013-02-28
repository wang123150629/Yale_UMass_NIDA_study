% ERR=Profile_Load()
%   This function is used to load the settings for the current profile,
%   including the profile's description, and preprocessing, filtering,
%   and feature settings.
%   
%   Input arguments:
%       none.
%       
%   Output arguments;
%       ERR - error value (true/false) 
%
% Written by Alex Andrews, 2011.

function bError=Profile_Load()

% Retrieve GUI object information
cObjects=vObjects();
sPaths=vPaths();

% ---------------------------
% -- 1.0 General GUI setup -- 
% ---------------------------

% Clear previous profile's persistent variables
Profile_ClearMemory();

% Get current profile
thisProfile=vCurrentProfile();

% Reset error value
bError=false;

% If no profile name selected, disable all processing elements on GUI
if isempty(thisProfile)
    % Clear and disable all profile-dependent objects
    for i=1:length(cObjects.ProfileDep)
        sObjectStyle=get(cObjects.ProfileDep{i,1},'style');
        if strcmpi(sObjectStyle,'checkbox')
           set(cObjects.ProfileDep{i,1},'Value',0) 
           set(cObjects.ProfileDep{i,1},'Enable','off')
        elseif strcmpi(sObjectStyle,'popupmenu')
           set(cObjects.ProfileDep{i,1},'Value',1) 
           set(cObjects.ProfileDep{i,1},'Enable','off') 
        elseif strcmpi(sObjectStyle,'edit')
           set(cObjects.ProfileDep{i,1},'String','')            
        else
            Comm_Warn(['Unexpected object style:  ',sObjectStyle])
        end       
    end
    
    % Set table data
    cCurrentData=get(cObjects.WindowTable{1},'Data');
    cBlankData=cell(size(cCurrentData,1),size(cCurrentData,2));           
    set(cObjects.WindowTable{1},'Data',cBlankData,...
       'Enable','off');           
    
    % Disable all other buttons (e.g., exporting buttons)
    set(cell2mat(cObjects.OtherButtons),'Enable','off')
    set(cell2mat(cObjects.FileAndProfileButtons),'Enable','off')
    % Clear all setting-dependent boxes
    set(cObjects.FeatureDesc,'String','');
    set(cObjects.FeatureDesc,'Enable','inactive');      
    set(cObjects.FiltSettingsLP,'String','')
    set(cObjects.FiltSettingsHP,'String','')
    set(cObjects.FiltSettingsNotch,'String','')
    % Clear index box
    set(cObjects.PlotIndex,'Value',1,'Enable','off','String','')
    % Empty filename box
    set(cObjects.Filename,'Value',1,'Enable','off','String','')
    % Reset last-selected variable
    Profile_UpdateLastSelected('all');
    % Exit function
    return
% If profile exists, but there is no filelist, then only enable some
elseif isempty(thisProfile.fileList)|isempty(thisProfile.dataSettings)
    % Clear and disable all profile-dependent objects
    for i=1:length(cObjects.ProfileDep)
        sObjectStyle=get(cObjects.ProfileDep{i,1},'style');
        if strcmpi(sObjectStyle,'checkbox')
           set(cObjects.ProfileDep{i,1},'Value',0) 
           set(cObjects.ProfileDep{i,1},'Enable','off')
        elseif strcmpi(sObjectStyle,'popupmenu')
           set(cObjects.ProfileDep{i,1},'Value',1) 
           set(cObjects.ProfileDep{i,1},'Enable','off') 
        elseif strcmpi(sObjectStyle,'edit')
           set(cObjects.ProfileDep{i,1},'String','')            
        else
            Comm_Warn(['Unexpected object type:  ',sObjectStyle])
        end       
    end
    
    % Set table data
    cCurrentData=get(cObjects.WindowTable{1},'Data');
    cBlankData=cell(size(cCurrentData,1),size(cCurrentData,2));           
    set(cObjects.WindowTable{1},'Data',cBlankData,'Enable','off');               
    % Disable all other buttons (e.g., exporting buttons)
    set(cell2mat(cObjects.OtherButtons),'Enable','off')
    set(cell2mat(cObjects.FileAndProfileButtons),'Enable','on')   
    % Clear all setting-dependent boxes
    set(cObjects.FeatureDesc,'String','');
    set(cObjects.FeatureDesc,'Enable','inactive');      
    set(cObjects.FiltSettingsLP,'String','')
    set(cObjects.FiltSettingsHP,'String','')
    set(cObjects.FiltSettingsNotch,'String','')
    % Clear index box
    set(cObjects.PlotIndex,'Value',1,'Enable','off','String','')
    % Empty filename box
    set(cObjects.Filename,'Value',1,'Enable','off','String','')
    
% Otherwise enable all elements
else
    % Enable all profile-dependent objects
    for i=1:length(cObjects.ProfileDep)
        sObjectStyle=get(cObjects.ProfileDep{i,1},'style');
        if strcmpi(sObjectStyle,'checkbox')
           set(cObjects.ProfileDep{i,1},'Enable','on')
        elseif strcmpi(sObjectStyle,'popupmenu')
           set(cObjects.ProfileDep{i,1},'Value',1) 
           set(cObjects.ProfileDep{i,1},'Enable','on')         
        elseif strcmpi(sObjectStyle,'edit')
            % Currently remains inactive
        else
            Comm_Warn(['Unexpected object type:  ',sObjectStyle])
        end              
    end
    
   % Set table data   
   cCurrentData=get(cObjects.WindowTable{1},'Data');
   cBlankData=cell(size(cCurrentData,1),size(cCurrentData,2));           
   set(cObjects.WindowTable{1},'Data',cBlankData,...
       'Enable','on');           
    % Enable all other buttons (e.g., exporting buttons)
    set(cell2mat(cObjects.OtherButtons),'Enable','on')
    set(cell2mat(cObjects.FileAndProfileButtons),'Enable','on')
    set(cObjects.PlotIndex,'Enable','on')
    set(cObjects.Filename,'Enable','on')    
end



% -----------------------------------
% -- 2.0 Load all profile settings --
% -----------------------------------


% Retrieve all fields from profile file
Profile_Settings=thisProfile.propertyList;
if ~isempty(thisProfile.dataSettings)
    if ~isempty(thisProfile.getChannel)
        Data_Settings=thisProfile.dataSettings{thisProfile.getChannel};
    else
        fprintf('No channel value stored (Profile_GetField)!\n\n');
        return
    end
    Profile_Settings=[Profile_Settings;Data_Settings];
end

% Enter profile specific information into fields
for i=1:length(cObjects.ProfileDep)
    % Skip tblWindow
    sObjectTag=get(cObjects.ProfileDep{i,1},'Tag');
    if strcmp(sObjectTag,'tblWindows'),continue,end
    
    iRow=strcmp(Profile_Settings(:,1),cObjects.ProfileDep{i,2});
    if all(~iRow),continue,end
    sObjectStyle=get(cObjects.ProfileDep{i,1},'style');
    % Update all checkbox values
    if strcmpi(sObjectStyle,'checkbox')
        set(cObjects.ProfileDep{i,1},'Value',str2double(Profile_Settings{iRow,2}));
    % Update all editbox strings
    elseif strcmpi(sObjectStyle,'edit')
        set(cObjects.ProfileDep{i,1},'String',Profile_Settings{iRow,2});
        
    % Check values for each popupmenu, and either select or give warning
    elseif strcmpi(sObjectStyle,'popupmenu')
        % Check values for smoothing filter type
        if strcmpi(Profile_Settings{iRow,1},'FILT_X_TYPE');
            sType=Profile_Settings{iRow,2};
            cTypes=get(cObjects.ProfileDep{i,1},'String');
            iFilt=find(strcmpi(cTypes,sType));
            % If filter not available, give warning and deselect smoothing
            if isempty(iFilt)
                Comm_Warn([sType,' filter not available.  Filter set ',...
                    'to ',cTypes{1},'.']);
                set(cObjects.ProfileDep{i,1},'Value',1);
                Profile_SetField('FILT_X_TYPE',cTypes{1})
            % If filter is available, select it in the drop-down
            else
                set(cObjects.ProfileDep{i,1},'Value',iFilt)                
            end
        % Check values for feature type    
        elseif strcmpi(Profile_Settings{iRow,1},'FEAT_TYPE');
            sType=Profile_Settings{iRow,2};
            cTypes=get(cObjects.ProfileDep{i,1},'String');
            iFeat=find(strcmpi(cTypes,sType));
            % If no features available, give warning
            if isempty(cTypes)
                Comm_Warn(sprintf(['No features available!  Check ',...
                    'features directory (%s%s)'],cd,sPaths.Features(3:end)));
                bError=true;
                return
            % If feature not available, give warning and change selection
            elseif isempty(iFeat)
                Comm_Warn(['"',sType,'" feature not available.  "',...
                    cTypes{1},'" used instead.']);
                temp=strcmp(cObjects.ProfileDep(:,2),'FEAT_TYPE');
                set(cObjects.ProfileDep{temp,1},'Value',1);
                Profile_SetField('FEAT_TYPE',cTypes{1})
            % If feature is available, select it in the drop-down and fill description box
            else
                set(cObjects.ProfileDep{i,1},'Value',iFeat)                               
                Process_CalcFeatures(['SetDesc-',sType],cObjects.FeatureDesc); 
            end       
            
        % Warn user if another popupmenu exists for which there is no code
        else
            Comm_Warn('Unexpected popupmenu');
        end
    
    end  
end

if ~isempty(thisProfile.dataSettings)
    % Load values into window table
    cTableData={'Baseline',...
        Profile_GetField(cObjects.WindowTable{2}{1},'to_num'),...
        Profile_GetField(cObjects.WindowTable{2}{2},'to_num');...
        'Target',...
        Profile_GetField(cObjects.WindowTable{2}{3},'to_num'),...
        Profile_GetField(cObjects.WindowTable{2}{4},'to_num')};
    set(cObjects.WindowTable{1},'Data',cTableData);
end

% Add in last-used filter settings
Profile_LoadFilterSettings('all');

% Update last-selected variable
Profile_UpdateLastSelected('all');
