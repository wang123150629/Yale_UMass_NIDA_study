function varargout = FeatureFinder(varargin)
% FeatureFinder M-file for FeatureFinder.fig
%      FeatureFinder, by itself, creates a new FeatureFinder or raises the existing
%      singleton*.
%
%      H = FeatureFinder returns the handle to a new FeatureFinder or the handle to
%      the existing singleton*.
%
%      FeatureFinder('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FeatureFinder.M with the given input arguments.
%
%      FeatureFinder('Property','Value',...) creates a new FeatureFinder or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FeatureFinder_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FeatureFinder_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FeatureFinder

% Last Modified by GUIDE v2.5 21-Mar-2012 08:22:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FeatureFinder_OpeningFcn, ...
                   'gui_OutputFcn',  @FeatureFinder_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FeatureFinder is made visible.
function FeatureFinder_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FeatureFinder (see VARARGIN)

% Determine whether FeatureFinder is already running
hdlAllFigs=findall(0,'Type','figure');
sFigureNames=get(hdlAllFigs,'Name');
sVisible=get(hdlAllFigs,'Visible');
if any(strcmp(sFigureNames,'FeatureFinder')&strcmp(sVisible,'on'))
    fprintf('WARNING:  FeatureFinder is already running.\n\n');
    return
end

% Choose default command line output for FeatureFinder
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FeatureFinder wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% ---------------------
% -- 1.0 - Setup GUI --
% ---------------------

clc

% Check compatibilty
bCompatible=Util_CheckCompatibilty();
if ~bCompatible
    delete(gcf);    
    return
end
set(gcf,'renderer','zbuffer');

% Check MATLAB paths
% Util_SortPaths(); commented out for V2.2.0
% function has been updated, but dealing with this issue in message board
% for now
% Add FeatureFinder to user's path
% Util_SetupPath(); commented out for V2.2.1

% Declare paths variables
sParDirectory=Util_GetFFDirectory();
sPaths.Profiles=[sParDirectory,'/Profiles'];
sPaths.Results=[sParDirectory,'/Results/'];
sPaths.Features=[sParDirectory,'/Features/'];
sPaths.Filters=[sParDirectory,'/Filters/'];
% sPaths.Norm='../NormInfo/';
vPaths('set',sPaths);

% Create windows table
hTable=fGUI_MakeWindowsTable(handles.pnlFeatures);
if isempty(hTable)
    fprintf('ERROR:  Could not create table.\n\n');
else
    cObjects.WindowTable=hTable;
    handles.tblWindows=hTable;
    guidata(hObject,handles);
end

% Setup objects variable which stores handles and corresponding field names
% (for dataSettings and propertyList fields in Profile objects)
cObjects.ProfileDep={...
    %handles.edtProfDesc,'DESCRIPTION';
    handles.chkNormalize,'PRE_NORM';
    handles.chkLP,'FILT_LP';
    handles.chkHP,'FILT_HP';
    handles.chkNotch,'FILT_NOTCH';
    handles.popOther,'FILT_X_TYPE';
    %handles.tblWindows,{'FEAT_BL_FROM','FEAT_BL_TO',...
    %    'FEAT_TARG_FROM','FEAT_TARG_TO'};
    handles.popFeatures,'FEAT_TYPE';    
    };
cObjects.RangeInfo={...
    1,2,'FEAT_BL_FROM';
    1,3,'FEAT_BL_TO';
    2,2,'FEAT_TARG_FROM';
    2,3,'FEAT_TARG_TO';    
    };
cObjects.FeatureDesc=handles.edtFeatures;
cObjects.PlotChecks={...
    handles.chkShowRaw,'PLOT_SHOWRAW';
    handles.chkShowPreview,'PLOT_SHOWPREVIEW';
    handles.chkPreviewFeatures,'PLOT_PREVIEWFEAT';
    };
cObjects.PlotMenus={...
    handles.popPar1,'PLOT_PAR1';
    handles.popPar2,'PLOT_PAR2';
    handles.popPar3,'PLOT_PAR3';
    handles.popPar4,'PLOT_PAR4';
    handles.popPar5,'PLOT_PAR5';
    handles.popPar6,'PLOT_PAR6';
    };
cObjects.PlotMenuTitles={...
    handles.txtPar1;
    handles.txtPar2;
    handles.txtPar3;
    handles.txtPar4;
    handles.txtPar5;
    handles.txtPar6;
    };
cObjects.PlotChan={handles.popChannel,'PLOT_CHAN'};
cObjects.PlotRegion={handles.popRegion,'PLOT_REGION'};    
cObjects.PlotButtons={...
    handles.cmdPrev;
    handles.cmdNext;
    handles.cmdFirst;
    handles.cmdLast;  
    };
cObjects.OtherButtons={...
    handles.cmdExportThis;
    handles.cmdExportAll;
    handles.cmdProcess;
    handles.hlpNorm;
    };
cObjects.FileAndProfileButtons={...    
    handles.cmdEditFilelist;
    handles.cmdEditProfile;
    handles.cmdDelete;    
    };
cObjects.FilterFields={...
    'FILT_NOTCH';'FILT_N_FREQ1';'FILT_N_FREQ2';'FILT_N_ORDER';
    'FILT_HP';'FILT_HP_FREQ';'FILT_HP_ORDER';
    'FILT_LP';'FILT_LP_FREQ';'FILT_LP_ORDER';
    'FILT_X_TYPE'
};
cObjects.Axes=handles.axes1;
cObjects.Main=handles.figure1;
cObjects.ProfileMenu=handles.popProfile;
cObjects.Preview=handles.chkShowPreview;
cObjects.PlotIndex=handles.txtIndex;
cObjects.Filename=handles.txtFilename;
cObjects.FiltSettingsLP=handles.lblLP;
cObjects.FiltSettingsHP=handles.lblHP;
cObjects.FiltSettingsNotch=handles.lblNotch;
cObjects.WindowTable={handles.tblWindows,{'FEAT_BL_FROM','FEAT_BL_TO',...
    'FEAT_TARG_FROM','FEAT_TARG_TO'}};

% Save the cObjects variable using its setter function
vObjects('set',cObjects);

% Setup last-selected variable (used to undo same-item selection, which led
% to crashes because of the corresponding 0 value)
cLastSelected={...
    handles.popProfile,0;
    handles.popOther,0;
    handles.popFeatures,0;
    handles.popPar1,0;
    handles.popPar2,0;
    handles.popPar3,0;
    handles.popPar4,0;
    handles.popPar5,0;
    handles.popPar6,0;
    handles.popChannel,0;
    handles.popRegion,0;
    handles.tblWindows,0
    };
vLastSelected('set',cLastSelected);

cFieldNames=fieldnames(handles);

nColor=Util_GetSystemColor(0);    
for i=1:length(cFieldNames)  
    nThisHandle=getfield(handles,cFieldNames{i});
    if strcmpi(get(nThisHandle,'Tag'),'figure1');
        set(nThisHandle,'Color',nColor);
    elseif isprop(nThisHandle,'Style')
        sObjectStyle=get(nThisHandle,'Style');
        if any(strcmpi(sObjectStyle,{'text','panel'}))
            set(getfield(handles,cFieldNames{i}),'BackgroundColor',nColor);
        end
    elseif isprop(nThisHandle,'Tag')
        sTag=get(nThisHandle,'Tag');
        if length(sTag)>=3&strcmp(sTag(1:3),'pnl')
            set(getfield(handles,cFieldNames{i}),'BackgroundColor',nColor);
        end
    end
end

% Load profile menu
Profile_FillMenu(handles.popProfile,sPaths.Profiles);

% Clear profile
vCurrentProfile('clear');

% Load smoothing filter menu
%Fill_Menu('Smooth',handles.popOther);
Process_Filter('setup-filters',{handles.popOther});

% Load feature menu
Process_CalcFeatures('setup-features',{handles.popFeatures});

% Disable all options
Profile_Load();

% Disable all plot options
Plot_LoadOptions();

% Transfer all position information to default cell
cPosns={};
cObjectHandles=fieldnames(handles);
for i=1:length(cObjectHandles)
    h=getfield(handles,cObjectHandles{i});
    cPosns=setfield(cPosns,cObjectHandles{i},get(h,'Position'));
end
vPosns('set',cPosns);

% Setup GUI
fSetupGUISize(handles);


% --- Outputs from this function are returned to the command line.
function varargout = FeatureFinder_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles)
    varargout{1} = handles.output;
end


% --------------------------------------------------------------------
function mnuFILE_Callback(hObject, eventdata, handles)
% hObject    handle to mnuFILE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --------------------------------------------------------------------
function mnuHELP_Callback(hObject, eventdata, handles)
% hObject    handle to mnuHELP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnuHelp_Callback(hObject, eventdata, handles)
% hObject    handle to mnuHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnuAbout_Callback(hObject, eventdata, handles)
% hObject    handle to mnuAbout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

figAbout();

% --------------------------------------------------------------------
function mnuExit_Callback(hObject, eventdata, handles)
% hObject    handle to mnuExit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Comm_Exit();

% --- Executes on selection change in popProfile.
function popProfile_Callback(hObject, eventdata, handles)
% hObject    handle to popProfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popProfile contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popProfile

% Get popup variables and current selection
cTemp=get(hObject,'String');
nVal=get(hObject,'Value');

% If 'Select...' selected, clear gui
if strcmp(cTemp{nVal},'Select...')
    vCurrentProfile('clear');
    Profile_Load();
    Plot_LoadOptions();
    Profile_UpdateLastSelected('this',hObject);

else
    % Otherwise load profile
    vCurrentProfile('set_name',cTemp{nVal});
    thisProfile=vCurrentProfile();
    if ~isempty(thisProfile.fileList)
        bError=Process_CalcFeatures(cTemp{nVal},'setup-windows',{handles.popFeatures,handles.tblWindows});
    else
        bError=0;
    end
    if ~bError
        bError=Profile_Load();
        if ~bError
            Plot_LoadOptions();
            Plot_Change(0);
            Plot_Data(handles.axes1);
            Profile_UpdateLastSelected('this',hObject);
        end
    end
end




% --- Executes during object creation, after setting all properties.
function popProfile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popProfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edtProfDesc_Callback(hObject, eventdata, handles)
% hObject    handle to edtProfDesc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtProfDesc as text
%        str2double(get(hObject,'String')) returns contents of edtProfDesc as a double


% --- Executes during object creation, after setting all properties.
function edtProfDesc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtProfDesc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox6.
function checkbox6_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox6


% --- Executes on button press in checkbox5.
function checkbox5_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox5


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popOther.
function popOther_Callback(hObject, eventdata, handles)
% hObject    handle to popOther (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popOther contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popOther

Profile_UpdateLastSelected('this',hObject)
Profile_SaveGUI(handles.popProfile);
nVal=get(handles.chkShowPreview,'Value');
if nVal,Plot_Data(handles.axes1),end


% --- Executes during object creation, after setting all properties.
function popOther_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popOther (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkLP.
function chkLP_Callback(hObject, eventdata, handles)
% hObject    handle to chkLP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkLP

Profile_SaveGUI(handles.popProfile);
Profile_LoadFilterSettings('LP');
nVal=get(handles.chkShowPreview,'Value');
if nVal,Plot_Data(handles.axes1),end


% --- Executes on button press in chkHP.
function chkHP_Callback(hObject, eventdata, handles)
% hObject    handle to chkHP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkHP
Profile_SaveGUI(handles.popProfile);
Profile_LoadFilterSettings('HP');
nVal=get(handles.chkShowPreview,'Value');
if nVal,Plot_Data(handles.axes1),end


% --- Executes on button press in cmdProcess.
function cmdProcess_Callback(hObject, eventdata, handles)
% hObject    handle to cmdProcess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get profile name
thisProfile=vCurrentProfile();
sProfile=thisProfile.name();
Process_AllData(sProfile);

function edtFeatures_Callback(hObject, eventdata, handles)
% hObject    handle to edtFeatures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtFeatures as text
%        str2double(get(hObject,'String')) returns contents of edtFeatures as a double


% --- Executes during object creation, after setting all properties.
function edtFeatures_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtFeatures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popFeatures.
function popFeatures_Callback(hObject, eventdata, handles)
% hObject    handle to popFeatures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popFeatures contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popFeatures


Profile_UpdateLastSelected('this',hObject)
% Fill description box
cTemp=get(hObject,'String');
nVal=get(hObject,'Value');
Process_CalcFeatures(['SetDesc-',cTemp{nVal}],handles.edtFeatures);
% Save profile
Profile_SaveGUI(handles.popProfile);
nVal=get(handles.chkShowPreview,'Value');
if nVal,Plot_Data(handles.axes1),end


% --- Executes during object creation, after setting all properties.
function popFeatures_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popFeatures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkNormalize.
function chkNormalize_Callback(hObject, eventdata, handles)
% hObject    handle to chkNormalize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkNormalize

% Determine state of checkbox
nVal=get(hObject,'Value');

% Determine number of parameters in use
thisProfile=vCurrentProfile();
nNumParams=size(thisProfile.fileList,2)-1;

% If norm box is unselected, replot only if preview selected
if nVal==0
    bShowPrev=get(handles.chkShowPreview,'Value');
    Profile_SaveGUI(handles.popProfile);
    if bShowPrev,Plot_Data(handles.axes1),end

% If norm is selected and there is a sufficient number of params, turn on
% preview and replot
elseif nVal==1&nNumParams>=2
    set(handles.chkShowPreview,'Value',1);
    set(handles.chkPreviewFeatures,'Enable','on');
    bShowPrev=get(handles.chkShowPreview,'Value');
    Profile_SaveGUI(handles.popProfile);
    if bShowPrev,Plot_Data(handles.axes1),end    

% If norm is selected and there isn't a sufficient number of params, change
% back selection and alert user
else
    set(hObject,'Value',0);
    Profile_SaveGUI(handles.popProfile);
    Comm_Warn('At least two parameters required for normalization.');
end

% --- Executes on selection change in popPar1.
function popPar1_Callback(hObject, eventdata, handles)
% hObject    handle to popPar1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popPar1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popPar1

% If new selection is not valid, set closest
Profile_SaveGUI(handles.popProfile);
if Plot_SetBestMatch(1);
    Profile_SaveGUI(handles.popProfile);
end

if Plot_Change(0)
    Profile_UpdateLastSelected('this',hObject)    
    Plot_Data(handles.axes1);
else
    Profile_RevertLastSelected();    
end


% --- Executes during object creation, after setting all properties.
function popPar1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popPar1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popPar2.
function popPar2_Callback(hObject, eventdata, handles)
% hObject    handle to popPar2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popPar2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popPar2

% If new selection is not valid, set closest
Profile_SaveGUI(handles.popProfile);
if Plot_SetBestMatch(2);
    Profile_SaveGUI(handles.popProfile);
end

% If new file is valid, then plot;
if Plot_Change(0)
    Profile_UpdateLastSelected('this',hObject)    
    Plot_Data(handles.axes1);
else
    Profile_RevertLastSelected();    
end


% --- Executes during object creation, after setting all properties.
function popPar2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popPar2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popPar3.
function popPar3_Callback(hObject, eventdata, handles)
% hObject    handle to popPar3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popPar3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popPar3

% If new selection is not valid, set closest
Profile_SaveGUI(handles.popProfile);
if Plot_SetBestMatch(3);
    Profile_SaveGUI(handles.popProfile);
end

% If new file is valid, then plot
if Plot_Change(0)
    Profile_UpdateLastSelected('this',hObject)    
    Plot_Data(handles.axes1);
else
    Profile_RevertLastSelected();    
end

% --- Executes during object creation, after setting all properties.
function popPar3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popPar3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
% Clear persistent variables
Exit_Program();

% --- Executes on selection change in popPar4.
function popPar4_Callback(hObject, eventdata, handles)
% hObject    handle to popPar4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popPar4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popPar4

% If new selection is not valid, set closest
Profile_SaveGUI(handles.popProfile);
if Plot_SetBestMatch(4);
    Profile_SaveGUI(handles.popProfile);
end

% If new file is valid, then plot
if Plot_Change(0)
    Profile_UpdateLastSelected('this',hObject)    
    Plot_Data(handles.axes1);
else
    Profile_RevertLastSelected();    
end

% --- Executes during object creation, after setting all properties.
function popPar4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popPar4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popPar5.
function popPar5_Callback(hObject, eventdata, handles)
% hObject    handle to popPar5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popPar5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popPar5

% If new selection is not valid, set closest
Profile_SaveGUI(handles.popProfile);
if Plot_SetBestMatch(5);
    Profile_SaveGUI(handles.popProfile);
end

% If new file is valid, then plot
if Plot_Change(0)
    Profile_UpdateLastSelected('this',hObject)    
    Plot_Data(handles.axes1);
else
    Profile_RevertLastSelected();    
end

% --- Executes during object creation, after setting all properties.
function popPar5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popPar5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popPar6.
function popPar6_Callback(hObject, eventdata, handles)
% hObject    handle to popPar6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popPar6 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popPar6

% If new selection is not valid, set closest
Profile_SaveGUI(handles.popProfile);
if Plot_SetBestMatch(6);
    Profile_SaveGUI(handles.popProfile);
end

% If new file is valid, then plot
if Plot_Change(0)
    Profile_UpdateLastSelected('this',hObject)    
    Plot_Data(handles.axes1);
else
    Profile_RevertLastSelected();    
end

% --- Executes during object creation, after setting all properties.
function popPar6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popPar6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkShowRaw.
function chkShowRaw_Callback(hObject, eventdata, handles)
% hObject    handle to chkShowRaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkShowRaw

Profile_SaveGUI(handles.popProfile);
Plot_Data(handles.axes1)

% --- Executes on button press in chkShowProc.
function chkShowProc_Callback(hObject, eventdata, handles)
% hObject    handle to chkShowProc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkShowProc

% Enables features checkbox only if value is 1
if get(hObject,'Value')==1
    set(handles.chkProcFeatures,'Value',1);
    set(handles.chkProcFeatures,'Enable','on');
else
    set(handles.chkProcFeatures,'Value',0);
    set(handles.chkProcFeatures,'Enable','off');
end

% Save GUI state and replot data
Profile_SaveGUI(handles.popProfile);
Plot_Data(handles.axes1)

% --- Executes on button press in chkShowPreview.
function chkShowPreview_Callback(hObject, eventdata, handles)
% hObject    handle to chkShowPreview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkShowPreview

% Enables features checkbox only if value is 1
if get(hObject,'Value')==1
    set(handles.chkPreviewFeatures,'Value',1);
    set(handles.chkPreviewFeatures,'Enable','on');
else
    set(handles.chkPreviewFeatures,'Value',0);
    set(handles.chkPreviewFeatures,'Enable','off');
end

% Save GUI state and replot data
Profile_SaveGUI(handles.popProfile);
Plot_Data(handles.axes1)

% --- Executes on button press in chkPreviewFeatures.
function chkPreviewFeatures_Callback(hObject, eventdata, handles)
% hObject    handle to chkPreviewFeatures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkPreviewFeatures

Profile_SaveGUI(handles.popProfile);
Plot_Data(handles.axes1)


function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popBL_From.
function popBL_From_Callback(hObject, eventdata, handles)
% hObject    handle to popBL_From (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popBL_From contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popBL_From


thisProfile=vCurrentProfile();
sProfile=thisProfile.name;

% If new value is valid, set
Profile_SaveGUI(handles.popProfile);
if ~Process_CheckWindows(sProfile);
    Profile_UpdateLastSelected('this',hObject);
    nVal=get(handles.chkShowPreview,'Value');
    if nVal,Plot_Data(handles.axes1),end
end

% --- Executes during object creation, after setting all properties.
function popBL_From_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popBL_From (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popBL_To.
function popBL_To_Callback(hObject, eventdata, handles)
% hObject    handle to popBL_To (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popBL_To contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popBL_To

thisProfile=vCurrentProfile();
sProfile=thisProfile.name;

% If new value is valid, set
Profile_SaveGUI(handles.popProfile);
if ~Process_CheckWindows(sProfile);
    Profile_UpdateLastSelected('this',hObject);
    nVal=get(handles.chkShowPreview,'Value');
    if nVal,Plot_Data(handles.axes1),end
end

% --- Executes during object creation, after setting all properties.
function popBL_To_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popBL_To (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popTarget_From.
function popTarget_From_Callback(hObject, eventdata, handles)
% hObject    handle to popTarget_From (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popTarget_From contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popTarget_From

thisProfile=vCurrentProfile();
sProfile=thisProfile.name;

% If new value is valid, set
Profile_SaveGUI(handles.popProfile);
if ~Process_CheckWindows(sProfile);
    Profile_UpdateLastSelected('this',hObject);
    nVal=get(handles.chkShowPreview,'Value');
    if nVal,Plot_Data(handles.axes1),end
end

% --- Executes during object creation, after setting all properties.
function popTarget_From_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popTarget_From (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popTarget_To.
function popTarget_To_Callback(hObject, eventdata, handles)
% hObject    handle to popTarget_To (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popTarget_To contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popTarget_To

thisProfile=vCurrentProfile();
sProfile=thisProfile.name;

% If new value is valid, set
Profile_SaveGUI(handles.popProfile);
if ~Process_CheckWindows(sProfile);
    Profile_UpdateLastSelected('this',hObject);
    nVal=get(handles.chkShowPreview,'Value');
    if nVal,Plot_Data(handles.axes1),end
end

% --- Executes during object creation, after setting all properties.
function popTarget_To_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popTarget_To (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cmdPrev.
function cmdPrev_Callback(hObject, eventdata, handles)
% hObject    handle to cmdPrev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Don't proceed if function is already running
%{
persistent bAmIRunning
if bAmIRunning 
    return
else
    bAmIRunning=true;
end
%}

% If previous plot is valid, load
bChange=Plot_Change(-1);
if bChange,Plot_Data(handles.axes1);end

%bAmIRunning=false;

% --- Executes on button press in cmdNext.
function cmdNext_Callback(hObject, eventdata, handles)
% hObject    handle to cmdNext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Don't proceed if function is already running
%{
persistent bAmIRunning
if bAmIRunning 
    return
else
    bAmIRunning=true;
end
%}

% If previous plot is valid, load
bChange=Plot_Change(1);
if bChange,Plot_Data(handles.axes1);end

%bAmIRunning=false;

% --- Executes on button press in cmdFirst.
function cmdFirst_Callback(hObject, eventdata, handles)
% hObject    handle to cmdFirst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Jump to first plot in list
Plot_Jump(1)
Plot_Data(handles.axes1)

% --- Executes on button press in cmdLast.
function cmdLast_Callback(hObject, eventdata, handles)
% hObject    handle to cmdLast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Jump to last plot in list
Plot_Jump(-1)
Plot_Data(handles.axes1)


% --- Executes on button press in cmdExportThis.
function cmdExportThis_Callback(hObject, eventdata, handles)
% hObject    handle to cmdExportThis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Retrieve GUI object information
cObjects=vObjects();
thisProfile=vCurrentProfile();
sProfile=thisProfile.name;
nChan=thisProfile.getChannel;

% -----------------------------------
% -- 1.0 Determine output filename --
% -----------------------------------

% 1.1 Attempt to create valid default filename
cPlotPar=Profile_GetField(cObjects.PlotMenus(:,2),'to_string');
sRawFilename=Profile_GetFilename(cPlotPar);
if isempty(sRawFilename)
    Comm_Warn('No filename in profile corresponds to selected parameters.');
    return
end
cFilelist=thisProfile.fileList;
nNumParams=size(cFilelist,2)-1;
sNamePattern='%s(Col%0.0f).txt';
for i=2:nNumParams
    sNamePattern=['%s-',sNamePattern];
end
sDefault=sprintf(sNamePattern,cPlotPar{1:nNumParams},nChan);

% 1.2 Prompt user for filename (give default)
[filename, pathname]=uiputfile({'*.txt','ASCII text file (*.txt)'},'Export data',sDefault);
if pathname==0 & filename==0
    return
end
sFiltFilename=[pathname,filename];
fidFiltData=Util_CheckFilename(sFiltFilename,'w-nocheck');

% ----------------------
% -- 2.0 Process data --
% ----------------------

Fs=Profile_GetField('FS','to_num');

% 2.1 If preview is not selected, give warning and return
temp=Profile_GetField(cObjects.PlotChecks(:,2),'to_bool');
bShowPreview=temp(2); 
if ~(bShowPreview)
    Comm_Warn('Please display preview data before exporting.');
    return
end

% 2.2 Load raw data
temp=Data_LoadRaw(sRawFilename);
if isempty(temp)
    Comm_Warn('Raw data not found (Plot_PlotData).');
    return
end
nRawSamples=[1:size(temp,1)]';
nRawTime=nRawSamples/Fs;
nRawData=temp(:,nChan);

% 2.4 Process data
[nPrevData nPrevTime nFeatures sFeature]=Process_ThisData(nRawData,nRawSamples,Fs); 
nData=[nPrevTime nPrevData];

% -------------------
% -- 3.0 Save data --
% -------------------

% 3.1 Create header
bNormalize=Profile_GetField('PRE_NORM','to_bool');
bFiltNotch=Profile_GetField('FILT_NOTCH','to_bool');
bFiltLP=Profile_GetField('FILT_LP','to_bool');
bFiltHP=Profile_GetField('FILT_HP','to_bool');
sFiltType=Profile_GetField('FILT_X_TYPE','to_string');
if ~bFiltLP
    sFiltLP='none';
else
    nOrder=Profile_GetField('FILT_LP_ORDER','to_num');
    nFreq=Profile_GetField('FILT_LP_FREQ','to_num');
    sFiltLP=sprintf('%g%s order, %g Hz',nOrder,Util_GetSuffix(nOrder),nFreq);    
end
if ~bFiltHP
    sFiltHP='none';
else
    nOrder=Profile_GetField('FILT_HP_ORDER','to_num');
    nFreq=Profile_GetField('FILT_HP_FREQ','to_num');
    sFiltHP=sprintf('%g%s order, %g Hz',nOrder,Util_GetSuffix(nOrder),nFreq);    
end
if ~bFiltNotch
    sFiltNotch='none';
else
    nOrder=Profile_GetField('FILT_N_ORDER','to_num');
    nFreq1=Profile_GetField('FILT_N_FREQ1','to_num');
    nFreq2=Profile_GetField('FILT_N_FREQ2','to_num');
    sFiltNotch=sprintf('%g%s order, %g-%g Hz',nOrder,Util_GetSuffix(nOrder),nFreq1,nFreq2);    
end
cFeatureSummary={['  Raw filename:  ',sRawFilename];...
    ['  HP filter:  ',sFiltHP];...
    ['  LP filter:  ',sFiltLP];...
    ['  Notch filter:  ',sFiltNotch];...
    ['  Other filter:  ',sFiltType];...
    ['  Normalization:  ',num2str(bNormalize)]};
cDataHeader={['File processed on ',datestr(now,'mmmm dd, yyyy'),' for the profile ',sProfile],cFeatureSummary{:}};
sChanName=thisProfile.chanInfo.titles{nChan};
 
% 3.2 Write header with processing information to processed data file    
fprintf(fidFiltData,'%s\n',cDataHeader{:});

% 3.3 Write column headers and data to processed data file
sPattern=Util_GeneratePattern(size(nData,2),'%s','\t','\n');  %*
fprintf(fidFiltData,sPattern,'Time (s)',sChanName);
sPattern=Util_GeneratePattern(size(nData,2),'%e','\t','\n');  %*
fprintf(fidFiltData,sPattern,nData');
fclose(fidFiltData);

% 3.4 Alert user
Comm_Alert('Filtered data has been saved');


% --- Executes on button press in cmdExportAll.
function cmdExportAll_Callback(hObject, eventdata, handles)
% hObject    handle to cmdExportAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Retrieve GUI object information
cObjects=vObjects();
thisProfile=vCurrentProfile();
sProfile=thisProfile.name;

% -----------------------------------
% -- 1.0 Determine output filename --
% -----------------------------------

% 1.1 Prompt user for location in which to store data
sSavePath=uigetdir('','Please select directory to save smoothed data');
sSavePath(sSavePath=='\')='/';
if sSavePath==0
    return
end

% 1.2 Define filename naming convention to use when storing data
% (dash-delimited parameters)
cFilelist=thisProfile.fileList; 
nNumParams=size(cFilelist,2)-1;
sNamePattern='%s(Col%0.0f).txt';
for i=2:nNumParams
    sNamePattern=['%s-',sNamePattern];
end
sNamePattern=[sSavePath,'/',sNamePattern];

% 1.3 Create header to save with each file
bNormalize=Profile_GetField('PRE_NORM','to_bool');
bFiltNotch=Profile_GetField('FILT_NOTCH','to_bool');
bFiltLP=Profile_GetField('FILT_LP','to_bool');
bFiltHP=Profile_GetField('FILT_HP','to_bool');
sFiltType=Profile_GetField('FILT_X_TYPE','to_string');
if ~bFiltLP
    sFiltLP='none';
else
    nOrder=Profile_GetField('FILT_LP_ORDER','to_num');
    nFreq=Profile_GetField('FILT_LP_FREQ','to_num');
    sFiltLP=sprintf('%g%s order, %g Hz',nOrder,Util_GetSuffix(nOrder),nFreq);    
end
if ~bFiltHP
    sFiltHP='none';
else
    nOrder=Profile_GetField('FILT_HP_ORDER','to_num');
    nFreq=Profile_GetField('FILT_HP_FREQ','to_num');
    sFiltHP=sprintf('%g%s order, %g Hz',nOrder,Util_GetSuffix(nOrder),nFreq);    
end
if ~bFiltNotch
    sFiltNotch='none';
else
    nOrder=Profile_GetField('FILT_N_ORDER','to_num');
    nFreq1=Profile_GetField('FILT_N_FREQ1','to_num');
    nFreq2=Profile_GetField('FILT_N_FREQ2','to_num');
    sFiltNotch=sprintf('%g%s order, %g-%g Hz',nOrder,Util_GetSuffix(nOrder),nFreq1,nFreq2);    
end
cFeatureSummary={['  HP filter:  ',sFiltHP];...
    ['  LP filter:  ',sFiltLP];...
    ['  Notch filter:  ',sFiltNotch];...
    ['  Other filter:  ',sFiltType];...
    ['  Normalization:  ',num2str(bNormalize)]};


% ----------------------
% -- 2.0 Process data --
% ----------------------

Fs=Profile_GetField('FS','to_num');

% 2.1 If preview is not selected, give warning and return
temp=Profile_GetField(cObjects.PlotChecks(:,2),'to_bool');
bShowPreview=temp(2); 
if ~(bShowPreview)
    Comm_Warn('Please display preview data before exporting.');
    return
end

% 2.2 Loop through all files
h=waitbar(0,'Processing and saving data...','WindowStyle','modal');
for iFile=1:size(cFilelist,1)

% 2.3 Load raw data
    sRawFilename=cFilelist{iFile,1};
    temp=Data_LoadRaw(sRawFilename);
    if isempty(temp)
        Comm_Warn('Raw data not found.');
        return
    end
    nChan=thisProfile.getChannel;
    nRawSamples=[1:size(temp,1)]';
    nRawTime=nRawSamples/Fs;
    nRawData=temp(:,nChan);

% 2.4 Process data
    [nPrevData nPrevTime nFeatures sFeature]=Process_ThisData(nRawData,nRawSamples,Fs); 
    nData=[nPrevTime nPrevData];
        

% -------------------
% -- 3.0 Save data --
% -------------------

% 3.1 Open filtered data file
    sFiltFilename=sprintf(sNamePattern,cFilelist{iFile,2:end},nChan);
    fidFiltData=fopen(sFiltFilename,'w');
    if fidFiltData==-1
        Comm_Warn(['Error saving to ',sFiltFilename])
        return
    end
    
    
% 3.2 Update file header
    cDataHeader={['File processed on ',datestr(now,'mmmm dd, yyyy'),' for the profile ',sProfile],...
        ['  Raw filename:  ',sRawFilename],...
        cFeatureSummary{:}};
 
% 3.3 Write header with processing information to processed data file    
    fprintf(fidFiltData,'%s\n',cDataHeader{:});

% 3.4 Write data to processed data file
    sChanName=thisProfile.chanInfo.titles{nChan};
    sPattern=Util_GeneratePattern(size(nData,2),'%s','\t','\n');  %*
    fprintf(fidFiltData,sPattern,'Time (s)',sChanName);
    sPattern=Util_GeneratePattern(size(nData,2),'%e','\t','\n');  %*
    fprintf(fidFiltData,sPattern,nData');
    fclose(fidFiltData);
    if ~ishandle(h)
        Comm_Alert('Data export interrupted!');
        return
    else        
        waitbar(iFile/size(cFilelist,1),h)
    end
end
close(h)

% 3.4 Alert user
Comm_Alert('Filtered data for selected channel has been saved. (Each channel must be exported individually.)');


% --- Executes on button press in chkNotch.
function chkNotch_Callback(hObject, eventdata, handles)
% hObject    handle to chkNotch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkNotch
Profile_SaveGUI(handles.popProfile);
Profile_LoadFilterSettings('Notch');
nVal=get(handles.chkShowPreview,'Value');
if nVal,Plot_Data(handles.axes1),end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over lblHP.
function lblHP_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to lblHP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Prompt user for new filter settings
if ~strcmp(get(hObject,'Enable'),'off')
    % Get current parameters
    nOrder=Profile_GetField('FILT_HP_ORDER','to_num');
    nFreq=Profile_GetField('FILT_HP_FREQ','to_num');
    Fs=Profile_GetField('FS','to_num');

    % Prompt for new parameters, using current parameters as default
    cNewVals=Util_InputWindow('HP filter','Choose new HP filter parameters:',...
        {'Order:','Cutoff freq. (Hz):'},...
        {'popmenu','floatedit'},...
        {[1:6],[0 round(Fs/2)]},...
        {nOrder,nFreq},false);
    if isempty(cNewVals),return,end
    
    % If dialog box not cancelled, save new values to file
    Profile_SetField('FILT_HP_ORDER',num2str(cNewVals{1}));
    Profile_SetField('FILT_HP_FREQ',num2str(cNewVals{2}));
    
    % Update text
    Profile_LoadFilterSettings('HP')    
    
    % Update plot
    nVal=get(handles.chkShowPreview,'Value');
    if nVal,Plot_Data(handles.axes1),end
end



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over lblLP.
function lblLP_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to lblLP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
% Prompt user for new filter settings
if ~strcmp(get(hObject,'Enable'),'off')
    % Get current parameters
    nOrder=Profile_GetField('FILT_LP_ORDER','to_num');
    nFreq=Profile_GetField('FILT_LP_FREQ','to_num');
    Fs=Profile_GetField('FS','to_num');
    
    % Prompt for new parameters, using current parameters as default
    cNewVals=Util_InputWindow('LP filter','Choose new LP filter parameters:',...
        {'Order:','Cutoff freq. (Hz):'},...
        {'popmenu','floatedit'},...
        {[1:6],[0 round(Fs/2)]},...
        {nOrder,nFreq},false);
    if isempty(cNewVals),return,end
    
    % If dialog box not cancelled, save new values to file
    Profile_SetField('FILT_LP_ORDER',num2str(cNewVals{1}));
    Profile_SetField('FILT_LP_FREQ',num2str(cNewVals{2}));
    
    % Update text
    Profile_LoadFilterSettings('LP')    
    
    % Update plot
    nVal=get(handles.chkShowPreview,'Value');
    if nVal,Plot_Data(handles.axes1),end
end


function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over edit6.
function edit6_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over lblNotch.
function lblNotch_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to lblNotch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Prompt user for new filter settings
if ~strcmp(get(hObject,'Enable'),'off')
    % Get current parameters
    nOrder=Profile_GetField('FILT_N_ORDER','to_num');
    nFreq1=Profile_GetField('FILT_N_FREQ1','to_num');
    nFreq2=Profile_GetField('FILT_N_FREQ2','to_num');
    Fs=Profile_GetField('FS','to_num');

    % Prompt for new parameters, using current parameters as default
    cNewVals=Util_InputWindow('Notch filter','Choose new notch filter parameters:',...
        {'Order:','Freq. 1 (Hz):','Freq. 2 (Hz):'},...
        {'popmenu','floatedit','floatedit'},...
        {[1:6],[0 round(Fs/2)],[0 round(Fs/2)]},...
        {nOrder,nFreq1,nFreq2},false);
    if isempty(cNewVals),return,end
    
    % If dialog box not cancelled, save new values to file
    if cNewVals{3}<cNewVals{2}
        temp=cNewVals{2};
        cNewVals{2}=cNewVals{3};
        cNewVals{3}=temp;
    end
    Profile_SetField('FILT_N_ORDER',num2str(cNewVals{1}));
    Profile_SetField('FILT_N_FREQ1',num2str(cNewVals{2}));
    Profile_SetField('FILT_N_FREQ2',num2str(cNewVals{3}));
    
    % Update text
    Profile_LoadFilterSettings('Notch')    
    
    % Update plot
    nVal=get(handles.chkShowPreview,'Value');
    if nVal,Plot_Data(handles.axes1),end
end


% --- Executes on button press in hlpNorm.
function hlpNorm_Callback(hObject, eventdata, handles)
% hObject    handle to hlpNorm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Get normalization parameters
thisProfile=vCurrentProfile();
if length(thisProfile.parNames)>=1
    sParamNames=sprintf('''%s'' parameter',thisProfile.parNames{1});
else
    Comm_Warn('No parameter names loaded.');
    return
end

% Create help strings
cHelp{1}='Normalize';
cHelp{2}=sprintf(['Normalization rescales the data as z-scores.  The ',...
    'mean and standard deviation of all data that share the same %s ',...
    'and channel are used for the z-score normalization.  Selected ',...
    'filtering options are carried out prior to normalization.'],...
    sParamNames);

% Display as help string
Comm_Help(cHelp{1},cHelp{2});
    


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Retrieve GUI object information
cPosns=vPosns();

% Define minimum, default, and current window size
nMinHeight=600;
nMinWidth=800;
if isempty(cPosns)
    %fprintf('ERROR:  cPosns is empty.  Returning window to minimum size.\n\n');
    %nCurrentPosn=get(handles.figure1,'Position');
    %set(handles.figure1,'Position',[nCurrentPosn(1) nCurrentPosn(2),...
    %    nMinWidth nMinHeight]);
    return
end
nDefaultHeight=cPosns.figure1(4);
nDefaultWidth=cPosns.figure1(3);
nWindowPosn=get(handles.figure1,'Position');
nWidth=nWindowPosn(3);nHeight=nWindowPosn(4);

% Snap window to minimum size if it gets too small
if nHeight<nMinHeight || nWidth<nMinWidth
    nWindowPosn(2)=nWindowPosn(2)+(nHeight<nMinHeight)*(nHeight-nMinHeight);
    nHeight=max([nHeight nMinHeight]);
    nWidth=max([nWidth nMinWidth]);
    set(handles.figure1,'Position',[nWindowPosn(1) nWindowPosn(2) nWidth nHeight])
end

% Determine change in size from default
dY=nHeight-nDefaultHeight;
dX=nWidth-nDefaultWidth;

nB_Stretch=dY;

% Update the profile panel
X=cPosns.pnlProfile;
set(handles.pnlProfile,'Position',[X(1) X(2)+nB_Stretch X(3) X(4)]);

% Update the PP and filter panels
X=cPosns.pnlPP;
set(handles.pnlPP,'Position',[X(1) X(2)+nB_Stretch X(3) X(4)]);
X=cPosns.pnlFilter;
set(handles.pnlFilter,'Position',[X(1) X(2)+nB_Stretch X(3) X(4)]);

% Update features panel
X=cPosns.pnlFeatures;
set(handles.pnlFeatures,'Position',[X(1) X(2) X(3) X(4)+nB_Stretch]);
X=cPosns.edtFeatures;
set(handles.edtFeatures,'Position',[X(1) X(2) X(3) X(4)+nB_Stretch]);
X=cPosns.tblWindows;
set(handles.tblWindows,'Position',[X(1) X(2) X(3) X(4)+nB_Stretch]);
% Loop through all other feature panel objects
cObjectHandles=fieldnames(cPosns);
for i=1:length(cObjectHandles)
    % If parent is feature panel and is not editbox, adjust position    
    hThisObject=getfield(handles,cObjectHandles{i});
    hParent=get(hThisObject,'Parent');
    if hParent==handles.pnlFeatures && hThisObject~=handles.edtFeatures
        X=getfield(cPosns,cObjectHandles{i});
        set(hThisObject,'Position',[X(1) X(2)+nB_Stretch X(3) X(4)]);
    end
end

% Update the plot panel
X=cPosns.pnlPlot;
set(handles.pnlPlot,'Position',[X(1) X(2) X(3)+dX X(4)+dY]);
X=cPosns.axes1;
set(handles.axes1,'Position',[X(1) X(2) X(3)+dX X(4)+dY]);
X=cPosns.cmdResetZoom;
set(handles.cmdResetZoom,'Position',[X(1)+dX X(2)+dY X(3) X(4)]);
X=cPosns.txtIndex;
set(handles.txtIndex,'Position',[X(1)+dX X(2) X(3) X(4)]);
X=cPosns.pnlPlotOpt;
set(handles.pnlPlotOpt,'Position',[X(1)+dX X(2) X(3) X(4)]);
X=cPosns.txtFilename;
set(handles.txtFilename,'Position',[X(1) X(2) X(3)+dX X(4)]);

% Update plot nav panel
X=cPosns.pnlPlotNav;
set(handles.pnlPlotNav,'Position',[X(1) X(2) X(3)+dX X(4)]);

X=cPosns.popPar1;set(handles.popPar1,'Position',[X(1) X(2) X(3)+0.25*dX X(4)]);
X=cPosns.popPar4;set(handles.popPar4,'Position',[X(1) X(2) X(3)+0.25*dX X(4)]);
X=cPosns.txtPar1;set(handles.txtPar1,'Position',[X(1) X(2) X(3)+0.25*dX X(4)]);
X=cPosns.txtPar4;set(handles.txtPar4,'Position',[X(1) X(2) X(3)+0.25*dX X(4)]);

X=cPosns.popPar2;set(handles.popPar2,'Position',[X(1)+.25*dX X(2) X(3)+0.25*dX X(4)]);
X=cPosns.popPar5;set(handles.popPar5,'Position',[X(1)+.25*dX X(2) X(3)+0.25*dX X(4)]);
X=cPosns.txtPar2;set(handles.txtPar2,'Position',[X(1)+.25*dX X(2) X(3)+0.25*dX X(4)]);
X=cPosns.txtPar5;set(handles.txtPar5,'Position',[X(1)+.25*dX X(2) X(3)+0.25*dX X(4)]);

X=cPosns.popPar3;set(handles.popPar3,'Position',[X(1)+.5*dX X(2) X(3)+0.25*dX X(4)]);
X=cPosns.popPar6;set(handles.popPar6,'Position',[X(1)+.5*dX X(2) X(3)+0.25*dX X(4)]);
X=cPosns.txtPar3;set(handles.txtPar3,'Position',[X(1)+.5*dX X(2) X(3)+0.25*dX X(4)]);
X=cPosns.txtPar6;set(handles.txtPar6,'Position',[X(1)+.5*dX X(2) X(3)+0.25*dX X(4)]);

X=cPosns.popChannel;set(handles.popChannel,'Position',[X(1)+.75*dX X(2) X(3)+0.25*dX X(4)]);
X=cPosns.popRegion;set(handles.popRegion,'Position',[X(1)+.75*dX X(2) X(3)+0.25*dX X(4)]);
X=cPosns.txtChannel;set(handles.txtChannel,'Position',[X(1)+.75*dX X(2) X(3)+0.25*dX X(4)]);
X=cPosns.txtRegion;set(handles.txtRegion,'Position',[X(1)+.75*dX X(2) X(3)+0.25*dX X(4)]);


X=cPosns.cmdNext;
set(handles.cmdNext,'Position',[X(1)+dX X(2) X(3) X(4)]);
X=cPosns.cmdLast;
set(handles.cmdLast,'Position',[X(1)+dX X(2) X(3) X(4)]);

   
function X=vPosns(A,B,C)

persistent Posns

X=[];

% Clear variable if requested
if nargin==1 && strcmp(A,'clear')
    clear Posns
% Set variable if requested
elseif nargin==2 && strcmp(A,'set')
    Posns=B;
% Retrieve variable if requested
elseif nargin==0
    X=Posns;
% If command not recognized, alert user
else
    fprintf('WARNING:  Unrecognized command to vPosns\n\n');
end


% --- Executes on button press in cmdNewProfile.
function cmdNewProfile_Callback(hObject, eventdata, handles)
% hObject    handle to cmdNewProfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sPaths=vPaths();
cProfileNames=Profile.getProfileNames(sPaths.Profiles,'all_versions');

% Prompt user for profile name and sampling rate
cLastInput={'NewProfile','1000'};
bBadInput=1;
while bBadInput
    cInputs=Util_InputWindow('New profile','Please select profile parameters:',...
        {'Name:','Sample rate (Hz):'},...
        {'charedit','intedit'},...
        {'',[0 inf]},...
        cLastInput,false);
    cLastInput=cInputs;
    
    % If user closed window, exit function
    if isempty(cInputs)
        return        
    % If name input is empty or otherwise bad, prompt user
    elseif isempty(cInputs{1})||~ischar(cInputs{1})||~isvarname(cInputs{1})
        Comm_Warn('Bad profile name.  Please try again.');        
    % If name is not unique, prompt user
    elseif any(strcmpi(cInputs{1},cProfileNames))
        Comm_Warn('Profile already exists.  Please check ''Profiles'' directory and try again.');
    
    elseif isempty(cInputs{2})||isnan(cInputs{2})||cInputs{2}<=0
        Comm_Warn('Bad sampling rate.  Please try again.');
    else
        sName=cInputs{1};
        nFs=cInputs{2};
        bBadInput=0;
    end
    
end

% Create profile instance and update
thisProfile=Profile();
thisProfile.name=sName;
vCurrentProfile('set_value',thisProfile);
Profile_SetField('FS',num2str(nFs));

% Reload profile pop-up
Profile_FillMenu(handles.popProfile,sPaths.Profiles);
vLastSelected('reset');

% Select thisProfile in pop-up
cProfiles=get(handles.popProfile,'String');
iProfile=find(strcmp(cProfiles,sName));
if isempty(iProfile)||length(iProfile)~=1
    fprintf('ERROR:  Profile not found in drop-down (cmdNewProfile)\n\n');
    return    
end

% Load new profile
set(handles.popProfile,'Value',iProfile);
if ~isempty(thisProfile.fileList)
    Process_CalcFeatures(sName,'setup-windows',{handles.popFeatures,...
        handles.popBL_From,handles.popBL_To,handles.popTarget_From,handles.popTarget_To});
end

Profile_Load();
Plot_LoadOptions();
Plot_Change(0);
Plot_Data(handles.axes1);

% Load file manager
cmdEditFilelist_Callback(handles.cmdEditFilelist,[],handles)


% --- Executes on button press in cmdEditProfile.
function cmdEditProfile_Callback(hObject, eventdata, handles)
% hObject    handle to cmdEditProfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sPaths=vPaths();
cProfileNames=Profile.getProfileNames(sPaths.Profiles,'all_versions');

% Determine which profile is loaded
thisProfile=vCurrentProfile();
if isempty(thisProfile)
    fprintf('ERROR:  No profile currently loaded\n\n');
    return
end
% Remove current profile name from list
cProfileNames=setdiff(cProfileNames,thisProfile.name);
% Store original sample rate
nOrigFs=Profile_GetField('FS','to_num');

% Prompt user for profile name and sampling rate
cLastInput={thisProfile.name,Profile_GetField('FS','to_num')};
bBadInput=1;
while bBadInput
    cInputs=Util_InputWindow('Edit profile','Please select profile parameters:',...
        {'Name:','Sample rate (Hz):'},...
        {'charedit','intedit'},...
        {'',[0 inf]},...
        cLastInput,false);
    
    %cLastInput=cInputs; (commented out 120323 for better user experience)
    % If user closed window, exit function
    if isempty(cInputs)
        return        
    % If name input is empty or otherwise bad, prompt user
    elseif isempty(cInputs{1})||~ischar(cInputs{1})||~isvarname(cInputs{1})
        Comm_Warn('Bad profile name.  Please try again.');                
    % If name is not unique, prompt user
    elseif any(strcmpi(cInputs{1},cProfileNames))
        Comm_Warn('Profile name already used.  Please try again.');       
    elseif isempty(cInputs{2})||isnan(cInputs{2})||cInputs{2}<=0
        Comm_Warn('Bad sampling rate.  Please try again.');        
    else
        sName=cInputs{1};
        nFs=cInputs{2};
        bBadInput=0;
    end
    
end

% Create new profile
newProfile=thisProfile;

% Delete old profile
thisProfile.deleteMe;

% Update new profile
newProfile.name=sName;
vCurrentProfile('set_value',newProfile);
Profile_SetField('FS',num2str(nFs));

% Reload profile pop-up
Profile_FillMenu(handles.popProfile,sPaths.Profiles);

% Select thisProfile in pop-up
cProfiles=get(handles.popProfile,'String');
iProfile=find(strcmp(cProfiles,sName));
if isempty(iProfile)||length(iProfile)~=1
    fprintf('ERROR:  Profile not found in drop-down (cmdEditProfile)\n\n');
    return    
else
    set(handles.popProfile,'Value',iProfile);
end

% Edit filter parameters, if necessary
Fs=Profile_GetField('FS','to_num');
if ~isempty(newProfile.dataSettings)
    nLP_Cutoff=Profile_GetField('FILT_LP_FREQ','to_num');
    if nLP_Cutoff>Fs/2
        fprintf('NOTE:   Low-pass filter''s cutoff frequency revised due\n');
        fprintf('        to new sampling rate.\n\n')
        nLP_Cutoff=floor(0.9*Fs/2);
        Profile_SetField('FILT_LP_FREQ',num2str(nLP_Cutoff));
    end
    nHP_Cutoff=Profile_GetField('FILT_HP_FREQ','to_num');
    if nHP_Cutoff>Fs/2
        fprintf('NOTE:   High-pass filter''s cutoff frequency revised due\n');
        fprintf('        to new sampling rate.\n\n')
        nHP_Cutoff=ceil(0.1*Fs/2);
        Profile_SetField('FILT_HP_FREQ',num2str(nHP_Cutoff));
    end
    nNotch_Cutoff1=Profile_GetField('FILT_N_FREQ1','to_num');
    nNotch_Cutoff2=Profile_GetField('FILT_N_FREQ2','to_num');
    if nNotch_Cutoff1>Fs/2 | nNotch_Cutoff2>Fs/2
        fprintf('NOTE:   Notch filter''s cutoff frequencies revised due\n');
        fprintf('        to new sampling rate.\n\n')
        if Fs>120
            nNotch_Cutoff=[59 61];
        else
            nNotch_Cutoff=[floor(Fs/4) ceil(Fs/4)];
        end
        Profile_SetField('FILT_N_FREQ1',num2str(nNotch_Cutoff(1)));
        Profile_SetField('FILT_N_FREQ2',num2str(nNotch_Cutoff(2)));
    end
end
    
% Scale baseline and target windows, if necessary
if Fs~=nOrigFs&&~isempty(newProfile.dataSettings)
    cWindowNames={'FEAT_BL_FROM';'FEAT_BL_TO';'FEAT_TARG_FROM';'FEAT_TARG_TO'};
    nWindowVals=Profile_GetField(cWindowNames,'to_num');
    nWindowVals=nWindowVals*nOrigFs/Fs;
    for i=1:length(cWindowNames)
        Profile_SetField(cWindowNames{i},num2str(nWindowVals(i)));
    end
end

% Reload profile
Profile_Load;
Plot_Data(handles.axes1)

% --- Executes on button press in cmdDelete.
function cmdDelete_Callback(hObject, eventdata, handles)
% hObject    handle to cmdDelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sPaths=vPaths();
thisProfile=vCurrentProfile();

% Verify that user wishes to delete profile
sMessage=sprintf('Are you sure that you''d like to delete the ''%s'' profile?',...
    thisProfile.name);
sAnswer=questdlg(sMessage,'Delete Profile?','Yes','No','No');
if ~strcmp(sAnswer,'Yes')
    return
end

% Determine which profile is loaded
if isempty(thisProfile)
    fprintf('ERROR:  No profile currently loaded\n\n');    
else
    vCurrentProfile('clear');

    % Delete profile
    thisProfile.deleteMe;

    % Reload list
    Profile_FillMenu(handles.popProfile,sPaths.Profiles);

    % Clear GUI
    Profile_Load();
    Plot_LoadOptions();
    vLastSelected('reset');
end


% --- Executes on button press in cmdEditFilelist.
function cmdEditFilelist_Callback(hObject, eventdata, handles)
% hObject    handle to cmdEditFilelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Retrieve current filelist, parameter list, and channel info
thisProfile=vCurrentProfile;

% Open the file manager using current values as default
if ~isempty(thisProfile.fileList)
    if ~isempty(thisProfile.parNames) && ~isempty(thisProfile.chanInfo)
        cOut=FileManagement(thisProfile.fileList,...
            thisProfile.parNames,thisProfile.chanInfo);        
    elseif ~isempty(thisProfile.parNames)
        cOut=FileManagement(thisProfile.fileList,...
            thisProfile.parNames);        
    elseif ~isempty(thisProfile.chanInfo)
        cOut=FileManagement(thisProfile.fileList,...
            thisProfile.chanInfo);        
    else
        cOut=FileManagement(thisProfile.fileList);
    end
else
    cOut=FileManagement();
end

% If values returned by manager, update profile and gui
if ~isempty(cOut)
    
    % If profile has been cleared (i.e., cOut={''}), then delete
    % profile and recreate with same name
   if length(cOut)==1&&isempty(cOut{1})
       Profile_Clear;
       return
   end       
    
    newProfile=thisProfile;
    newProfile.fileList=cOut{1};
    newProfile.parNames=cOut{2};
    newProfile.chanInfo=cOut{3};
    
    % Setup profile with new files, but retain original channel settings
    temp=newProfile.dataSettings;
    newProfile=newProfile.setupWithFiles;
    if isempty(newProfile.dataSettings)
        Comm_Warn('File setup interrupted.  Changes to filelist not saved.');
        return
    end
    if ~isempty(temp)
        newProfile.dataSettings=temp;
    end
    
    % Check that smallest file in new filelist isn't shorter than any
    % channel's region positions
    Fs=str2num(newProfile.getField('FS'));    
    cBL_To=newProfile.getFieldForAllChans('FEAT_BL_TO');
    cTarg_To=newProfile.getFieldForAllChans('FEAT_TARG_TO');
    cBL_From=newProfile.getFieldForAllChans('FEAT_BL_FROM');
    cTarg_From=newProfile.getFieldForAllChans('FEAT_TARG_FROM');
    bChans=newProfile.chanInfo.toUse;
    nLargestBoundary=max([...
        cellfun(@str2num,cBL_To(bChans),'UniformOutput',true),...
        cellfun(@str2num,cTarg_To(bChans),'UniformOutput',true)]);    
    nMinFileLength=str2num(newProfile.getField('MAX_WIN_SAMPLES'))/Fs;
    nBL(1,:)=cellfun(@str2num,cBL_From(bChans),'UniformOutput',true);
    nBL(2,:)=cellfun(@str2num,cBL_To(bChans),'UniformOutput',true);
    nTarg(1,:)=cellfun(@str2num,cTarg_From(bChans),'UniformOutput',true);
    nTarg(2,:)=cellfun(@str2num,cTarg_To(bChans),'UniformOutput',true);
    %{
    if ~Process_CheckWindows('all-fix');
        thisProfile=newProfile;
    else
        Comm_Warn(['Filelist not changed as there may be a file of ',...'
            'length 0 or 1 samples']);
        return
    end
    %}
    
    if nLargestBoundary>nMinFileLength
        sMessage=sprintf(['For at least one channel, the placement of ',...
            'your baseline/target ',...
            'windows (up to %g s) extend past the end of your ',...
            'shortest file (%g s).  Do you wish to (a) cancel all ',...
            'changes to your filelist, or (b) automatically reposition ',...
            'your baseline/target windows?'],nLargestBoundary,nMinFileLength);
        sInput=questdlg(sMessage,'Windows outside of range','Cancel',...
            'Reposition','Reposition');
        if strcmp(sInput,'Reposition')
            thisProfile=newProfile;
            vCurrentProfile('set_value',thisProfile);
            
            iChans=find(bChans);
            sOrigChan=Profile_GetField('PLOT_CHAN','to_string');
            
            for i=1:length(iChans)
                iChan=iChans(i);
                Profile_SetField('PLOT_CHAN',thisProfile.chanInfo.titles{iChan});                
                
                % If only the upper end of one or both windows is too long,
                % reduce it to its max value
                if nBL(1,i)<=nMinFileLength&&nBL(2,i)>nMinFileLength
                    Profile_SetField('FEAT_BL_TO',num2str(nMinFileLength));                    
                end
                if nTarg(1,i)<=nMinFileLength&&nTarg(2,i)>nMinFileLength
                    Profile_SetField('FEAT_TARG_TO',num2str(nMinFileLength));                    
                end
            
                    
                % If the upper and lower ends of the baseline window are too long
                if all(nBL(1:2,i)>nMinFileLength)
                    % If the window length is small enough, shift the window so
                    % that its upper end is the max window value
                    if diff(nBL(1:2,i))<nMinFileLength
                        nShift=nBL(2,i)-nMinFileLength;
                        Profile_SetField('FEAT_BL_FROM',num2str(nBL(1,i)-nShift));
                        Profile_SetField('FEAT_BL_TO',num2str(nBL(2,i)-nShift));                              
                    % If the window length is larger than the file length, set
                    % to its default position
                    else
                        nAllMaxVal=nMinFileLength;nAllMinVal=1;
                        nRes=(nAllMaxVal-nAllMinVal+1)/1000/Fs;
                        nBL_From=ceil((nAllMinVal-1)/Fs/nRes)*nRes;
                        nBL_To=floor(mean([nAllMinVal-1,nAllMaxVal-1])/Fs/nRes)*nRes;
                        Profile_SetField('FEAT_BL_FROM',num2str(nBL_From));
                        Profile_SetField('FEAT_BL_TO',num2str(nBL_To));                  
                    end
                end

                % If the upper and lower ends of the target window are too long
                if all(nTarg(1:2,i)>nMinFileLength)
                    % If the window length is small enough, shift the window so
                    % that its upper end is the max window value
                    if diff(nTarg(1:2,i))<nMinFileLength
                        nShift=nTarg(2,i)-nMinFileLength;
                        Profile_SetField('FEAT_TARG_FROM',num2str(nTarg(1,i)-nShift));
                        Profile_SetField('FEAT_TARG_TO',num2str(nTarg(2,i)-nShift));
                    % If the window length is larger than the file length, set
                    % to its default position
                    else
                        nAllMaxVal=nMinFileLength;nAllMinVal=1;
                        nRes=(nAllMaxVal-nAllMinVal+1)/1000/Fs;
                        nTarg_From=ceil(mean([nAllMinVal-1,nAllMaxVal-1])/Fs/nRes)*nRes;
                        nTarg_To=floor((nAllMaxVal-1)/Fs/nRes)*nRes; 
                        Profile_SetField('FEAT_TARG_FROM',num2str(nTarg_From));
                        Profile_SetField('FEAT_TARG_TO',num2str(nTarg_To));                                     
                    end
                end           
            end
            Profile_SetField('PLOT_CHAN',sOrigChan);  
        else
            return
        end
        %{
        sMessage=sprintf(['FILELIST NOT CHANGED:  ',...
            'One or more files in the filelist are ',...
            'shorter than the current baseline and/or window ',...
            'regions.  The shortest file is %0.3f s and the baseline ',...
            'and/or target region for one or more channels extends ',...
            'past this point to %0.3f s.  Please revise the region limits ',...
            'and try again OR ensure that all selected files are ',...
            'sufficiently long.'],nMinFileLength,nLargestBoundary);
        Comm_Warn(sMessage);
        return
        %}
    else
        thisProfile=newProfile;
        vCurrentProfile('set_value',thisProfile);
    end  
    
    
    % If current channel is no longer in use, set as first avail
    if isempty(thisProfile.getChannel)|...
            ~thisProfile.chanInfo.toUse(thisProfile.getChannel)
        iFirst=find(thisProfile.chanInfo.toUse,1,'first');
        Profile_SetField('PLOT_CHAN',thisProfile.chanInfo.titles{iFirst});
    end
    
    if ~isempty(thisProfile.fileList)
        Process_CalcFeatures(thisProfile.name,'setup-windows',{handles.popFeatures});
    end
    
    Profile_Load();
    Plot_LoadOptions();
    Plot_Change(0);
    Plot_Data(handles.axes1);
end



% --- Executes on selection change in popChannel.
function popChannel_Callback(hObject, eventdata, handles)
% hObject    handle to popChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popChannel

% Get last selection
thisProfile=vCurrentProfile();
nLastChan=thisProfile.getChannel;
sLastChan=thisProfile.chanInfo.titles{nLastChan};

sAllChannels=get(hObject,'string');
nThisChannel=get(hObject,'value');
sThisChannel=sAllChannels{nThisChannel};

if ~strcmp(sLastChan,sThisChannel)
    Profile_SaveGUI(handles.popProfile);
    Profile_Load();
    Profile_LoadFilterSettings('all');
    Profile_UpdateLastSelected('this',hObject)    
    Plot_Data(handles.axes1);
end


% --- Executes during object creation, after setting all properties.
function popChannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popRegion.
function popRegion_Callback(hObject, eventdata, handles)
% hObject    handle to popRegion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popRegion contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popRegion


% --- Executes during object creation, after setting all properties.
function popRegion_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popRegion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function fSetupGUISize(handles)

% Define constants
nFillFraction=25/32;
nMinRes.X=800;
nMinRes.Y=600;

% Determine resolution of display
set(0,'Units','pixels');
nRes=get(0,'ScreenSize');

% If too small, give warning
if nRes(3)<nMinRes.X|nRes(4)<nMinRes.Y
   Comm_Warn(sprintf(['Your screen resolution is less than the required %0.0fx%0.0f! ',...
       'The program will continue, but you will likely experience ',...
       'display problems.'],nMinRes.X,nMinRes.Y));
elseif nRes(3)*nFillFraction<nMinRes.X|nRes(4)*nFillFraction<nMinRes.Y
    Comm_Warn(sprintf(['Your screen resolution is less than the ',...
        'recommended %0.0fx%0.0f.  You may experience display problems.'],...
        nMinRes.X/nFillFraction,nMinRes.Y/nFillFraction));
end

% Determine platform
% sPlatform=computer; % currently not used, could also use ispc/ismac

% Calculate optimal positioning (start with 80% of res or 600/800)
nMinOuterWidth=nMinRes.X;
nMinOuterHeight=nMinRes.Y;
nOuterWidth=max([nFillFraction*nRes(3),nMinOuterWidth]);
nOuterHeight=max([nFillFraction*nRes(4),nMinOuterHeight]);
nLeft=max([nRes(3)-nOuterWidth,0])/2;
nBottom=max([nRes(4)-nOuterHeight,0])/2;

% Set new coordinates and position
set(handles.figure1,'Units','pixels',...
    'OuterPosition',[nLeft nBottom nOuterWidth nOuterHeight])
figure1_ResizeFcn(0,0,handles);

% Add windows table to GUI
function hTable=fGUI_MakeWindowsTable(hFeatPanel)

% Specify table characteristics
nPos=[12 108 160 62];

hTable=uitable(hFeatPanel,'Units','pixels','Position',nPos,...
    'ColumnFormat',{'char','numeric','numeric'},'ColumnName',[],...
    'RowName',[],'ColumnWidth',{52 52 52},'FontUnits','pixels',...
    'FontSize',10,'Enable','off',...
    'CellEditCallback',{@tblWindow_Callback},...
    'Tag','tblWindows','Data',cell(2,3),...
    'ColumnEditable',logical([0 1 1]));


% --- Executes on selection change in tblWindow
function tblWindow_Callback(hObject, eventdata, handles)
% hObject    handle to popBL_From (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popBL_From contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popBL_From

cObjects=vObjects();

thisProfile=vCurrentProfile();
sProfile=thisProfile.name;

% If any entered values are non-numeric, reload values
cData=get(hObject,'Data');
if any(any(cellfun(@isnan,cData(:,2:end))));
    Profile_RevertLastSelected();
    return
end

% Check most recent change:  
% > is it within the expected time range?
% > does it result in any zero-length windows?
if Process_CheckWindows(sProfile,'this',eventdata)
    cData{eventdata.Indices(1),eventdata.Indices(2)}=...
        eventdata.PreviousData;
    set(hObject,'Data',cData);
    return
end

% If all table values are valid, plot data
Profile_SaveGUI(cObjects.ProfileMenu);
Process_CheckWindows(sProfile,'all-revert');
if ~Process_CheckWindows(sProfile,'all-revert')||...
        ~Process_CheckWindows(sProfile,'all-fix')
    Profile_UpdateLastSelected('this',hObject);
    nVal=get(cObjects.Preview,'Value');
    if nVal,Plot_Data(cObjects.Axes),end
end


% When user clicks figure, direct action based on click type and location (AA)
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)

% If no profile selected, exit function
if isempty(vCurrentProfile())
    return
end

% Determine click-point
nAxisPoint=get(handles.axes1,'CurrentPoint');
X=nAxisPoint(1,1);Y=nAxisPoint(1,2);

% ----------------------------
% -- Process clicks in axis --
% ----------------------------

% If click was in time-series axis, process accordingly
nAxisLim.X=get(handles.axes1,'xlim');
nAxisLim.Y=get(handles.axes1,'ylim');
if X>=nAxisLim.X(1)&&X<=nAxisLim.X(2)&&...
        Y>=nAxisLim.Y(1)&&Y<=nAxisLim.Y(2)
    sClickType=get(hObject,'SelectionType');
    switch sClickType
        % If left click
        case 'normal'
            
        % If double click, zoom in to clicked point
        case 'open'
            % Define new limits
            nOrigAxesLim.X=fLibrary('OrigXLim');
            nOrigAxesLim.Y=fLibrary('OrigYLim');
            nNewAxesLim.X=X+diff(nAxisLim.X)/4*[-1 1];
            nNewAxesLim.Y=Y+diff(nAxisLim.Y)/4*[-1 1];            
            % If new limits exceed orig. limits, shift accordingly (assumes
            % new limits are smaller than original)
            if nNewAxesLim.X(1)<nOrigAxesLim.X(1)
                nNewAxesLim.X=nNewAxesLim.X+(nOrigAxesLim.X(1)-...
                    nNewAxesLim.X(1));
            elseif nNewAxesLim.X(2)>nOrigAxesLim.X(2)
                nNewAxesLim.X=nNewAxesLim.X-(-nOrigAxesLim.X(2)+...
                    nNewAxesLim.X(2));
            end
            if nNewAxesLim.Y(1)<nOrigAxesLim.Y(1)
                nNewAxesLim.Y=nNewAxesLim.Y+(nOrigAxesLim.Y(1)-...
                    nNewAxesLim.Y(1));
            elseif nNewAxesLim.Y(2)>nOrigAxesLim.Y(2)
                nNewAxesLim.Y=nNewAxesLim.Y-(-nOrigAxesLim.Y(2)+...
                    nNewAxesLim.Y(2));
            end
            
            WindowFixedObjects=fLibrary('Axes1_WindowFixedObjects');
            if ~isempty(WindowFixedObjects)
                Plot_Zoom(handles.axes1,WindowFixedObjects.handles,...
                    WindowFixedObjects.info,nNewAxesLim);
            end
            
            % Save zoom settings to profile
            fLibrary('AxesLim',nNewAxesLim);
            
            %need to specify type of window fixed object: x, y, or xy (now its both)
            %then there needs to be a check in Plot_Zoom to see if a rectangles bounds
            %(in nCorner1 and nCorner2) are outside the axis limits... but i think 
            %    there should just be a property option (Clipping?)
            
        % If right click (or control click) 
        case 'alt'
            nOrigAxesLim.X=fLibrary('OrigXLim');
            nOrigAxesLim.Y=fLibrary('OrigYLim');
            WindowFixedObjects=fLibrary('Axes1_WindowFixedObjects');
            if ~isempty(WindowFixedObjects)
                Plot_Zoom(handles.axes1,WindowFixedObjects.handles,...
                    WindowFixedObjects.info,nOrigAxesLim)
            end
            
            % Save zoom settings to file
            fLibrary('AxesLim',[]);
            
        % If shift click (or left+right click)
        case 'extend'
            
        otherwise
            fprintf(['WARNING:  Unrecognized click-type ',...
                '(figure1_WindowButtonDownFcn).\n\n']);
    end   
end 


% --- Executes on button press in cmdResetZoom.
function cmdResetZoom_Callback(hObject, eventdata, handles)
% hObject    handle to cmdResetZoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

nOrigAxesLim.X=fLibrary('OrigXLim');
nOrigAxesLim.Y=fLibrary('OrigYLim');
WindowFixedObjects=fLibrary('Axes1_WindowFixedObjects');
if ~isempty(WindowFixedObjects)
    Plot_Zoom(handles.axes1,WindowFixedObjects.handles,...
        WindowFixedObjects.info,nOrigAxesLim)
end
