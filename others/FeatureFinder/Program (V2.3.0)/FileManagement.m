function varargout = FileManagement(varargin)
% FILEMANAGEMENT MATLAB code for FileManagement.fig
%      FILEMANAGEMENT, by itself, creates a new FILEMANAGEMENT or raises the existing
%      singleton*.
%
%      H = FILEMANAGEMENT returns the handle to a new FILEMANAGEMENT or the handle to
%      the existing singleton*.
%
%      FILEMANAGEMENT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FILEMANAGEMENT.M with the given input arguments.
%
%      FILEMANAGEMENT('Property','Value',...) creates a new FILEMANAGEMENT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FileManagement_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FileManagement_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FileManagement

% Last Modified by GUIDE v2.5 23-Jun-2011 16:13:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FileManagement_OpeningFcn, ...
                   'gui_OutputFcn',  @FileManagement_OutputFcn, ...
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


% --- Executes just before FileManagement is made visible.
function FileManagement_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FileManagement (see VARARGIN)

% Choose default command line output for FileManagement
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%global cOutput
%cOutput={};

%global hdlGUI
%hdlGUI=handles;

% Store figure positioning info
cPosns=[];
cObjectHandles=fieldnames(handles);
for i=1:length(cObjectHandles)
    h=getfield(handles,cObjectHandles{i});
    cPosns=setfield(cPosns,cObjectHandles{i},get(h,'Position'));
end
cPosns.FileColumnWidth=get(handles.tblFilelist,'ColumnWidth');
cPosns.ChanColumnWidth=get(handles.tblChannels,'ColumnWidth');
set(hObject,'UserData',cPosns);


% Check input variables

% If no inputs given, initialize variables
if isempty(varargin)
    vParNames('reset');
    vFilelist('reset');
    vFilechars('reset');

% If one input, check that it is a valid filelist
elseif length(varargin)<=3
    if vFilelist('isa',varargin{1})
        vFilelist('set',varargin{1});
        temp=vFilelist('getfilechars');
        if isempty(temp)
            Comm_Warn(['Error loading filelist!  See the "Command Window" ',...
                'for more information.']);            
            return
        end
        vFilechars('set',temp);
        % Could verify no duplicates here too.
        
    else
        fprintf('Bad first input argument to FileManagement.\n\n');
        return
    end
    
    % If two inputs, determine whether the parameter names or chan. info
    if length(varargin)==2
        if vParNames('isa',varargin{2})
            vParNames('set',varargin{2});
        elseif vChanInfo('isa',varargin{2})
            vChanInfo('set',varargin{2});
        else
            fprintf('Bad second input argument to FileManagement.\n\n');
        end
    % If three inputs, assume the order:  filelist, parameter names, channel info        
    elseif length(varargin)==3
        if vParNames('isa',varargin{2}) & vChanInfo('isa',varargin{3})
            vParNames('set',varargin{2});
            vChanInfo('set',varargin{3});
        else
            fprintf('Bad second or third input argument to FileManagement.\n\n');
        end
    end    
    
% If less than 0 or more than 3 inputs, return error
else
    fprintf('ERROR:  Bad number of inputs to FileManagement.m\n\n');
    return    
end

% Set GUI colours
cFieldNames=fieldnames(handles);
nColor=Util_GetSystemColor(0);  
for i=1:length(cFieldNames)  
    nThisHandle=getfield(handles,cFieldNames{i});
    if strcmpi(get(nThisHandle,'Tag'),'figure1');
        set(nThisHandle,'Color',nColor);
    elseif length(cFieldNames{i})>=3&strcmp(cFieldNames{i}(1:3),'tbl')
        set(getfield(handles,cFieldNames{i}),'Units','pixels',...
            'FontSize',11);
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

% Clear tables
set(handles.tblFilelist,'Data','')
set(handles.tblChannels,'Data','')

fLibrary('Output',{});
fLibrary('hdlGUI',handles);

fUpdateGUI();

% UIWAIT makes FileManagement wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FileManagement_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cOutput=fLibrary('Output');

% FileManagenment's outputs are temporarily stored in this global
% variable, which is now transferred to this output argument
varargout{1} = cOutput;
%clear cOutput
fLibrary('Output');
fLibrary('hdlGUI');

% The figure can be deleted now
delete(handles.figure1);



% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Is this code used?
fprintf('.\n'); % to check...
temp=get(handles.tblFilelist,'Data');
cData=temp(:,1);
if length(cData)>2 && ~all(cellfun(@isempty,cData(1:2)))&&...
        all(cellfun(@isempty,cData(3:end)))
    for i=3:length(cData)
        cData{i}=cData{i-1}+cData{2}-cData{1};
    end
    temp(:,1)=cData;
    set(handles.tblFilelist,'Data',temp)
end



% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Is this code used?
fprintf('.\n'); % to check...
temp=get(handles.tblFilelist,'Data');
cData=temp(:,2);
if length(cData)>1 && ~all(cellfun(@isempty,cData(1)))&&...
        all(cellfun(@isempty,cData(2:end)))
    cData(2:end)=cData(1);
    temp(:,2)=cData;
    set(handles.tblFilelist,'Data',temp)
end


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cmdCancel.
function cmdCancel_Callback(hObject, eventdata, handles)
% hObject    handle to cmdCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fLibrary('Output',{});
close(handles.figure1);

% --- Executes on button press in cmdOK.
function cmdOK_Callback(hObject, eventdata, handles)
% hObject    handle to cmdOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


cFilelist=vFilelist();
cParNames=vParNames();
cFilechars=vFilechars();

% Ensure that a new edit to either table is not missed (unless channel
% table is empty)
tblFilelist_CellEditCallback(handles.tblFilelist);
tblChannels_CellEditCallback(handles.tblChannels);

% If filelist is empty, output as such
if isempty(cFilelist)
    fLibrary('Output',{''});
    close(handles.figure1);
    return
end

% Check for problems in filelist
cErrorMsg={};
%if size(cFilelist,1)<1 % Commented out in V2.3.0 to allow user to easily
%                             clear filelist
%    cErrorMsg(end+1)={'Filelist must contain at least one file.'};
%end
if size(cFilelist,1)>=1&&size(cFilelist,2)<2
    cErrorMsg(end+1)={'Filelist must contain at least one parameter.'};
end

if isempty(cErrorMsg)
    nNumMissingParams=sum(sum(strcmp(cFilelist(:,2:end),'')));
    if nNumMissingParams>0
        cErrorMsg(end+1)={['Missing parameter values.  Please ensure that a value',... 
            ' has been entered for each file and parameter.']};
    else
        nAllDup=[];
        for i=1:size(cFilelist,1)-1
            nNumDuplicate=1;nDup=i;
            for j=i+1:size(cFilelist,1)
                if isequal(cFilelist(i,2:end),cFilelist(j,2:end))                    
                    if ~any(nAllDup==j)
                        nNumDuplicate=nNumDuplicate+1;
                        nDup(nNumDuplicate)=j;
                        nAllDup=[nAllDup j];
                    end
                end                
            end
            if nNumDuplicate>1
                sMessage='Duplicate parameter lists found at rows ';
                for k=1:nNumDuplicate-1
                    sMessage=[sMessage,'%0.0f, '];
                end
                sMessage=[sMessage(1:end-2),' and %0.0f.'];            
                cErrorMsg(end+1)={sprintf(sMessage,nDup)};
            end
        end
    end
    if any(cFilechars.headerLines~=cFilechars.headerLines(1))
        cErrorMsg(end+1)={'All files must exist and have the same number of headerlines.'};
    end
    if any(cFilechars.channels~=cFilechars.channels(1))
        cErrorMsg(end+1)={'All files must exist and have the same number of channels.'};
    end
end

% If there was an error, alert user, otherwise output data
if ~isempty(cErrorMsg)
    Comm_Warn(cErrorMsg);
    return;
else
    vFilelist('sort');
    cFilelist=vFilelist();
    cOutput={cFilelist,cParNames,vChanInfo()};
    close(handles.figure1);
end

fLibrary('Output',cOutput);
      



% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2


% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1

% Get number in pop-up menu
sMenu=get(hObject,'String');
nMenu=get(hObject,'Value');
nRows=str2double(sMenu{nMenu});

% Set table to have that number of rows
set(handles.tblFilelist,'Data',cell(nRows,4))

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cmdEditNames.
function cmdEditNames_Callback(hObject, eventdata, handles)
% hObject    handle to cmdEditNames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cParNames=vParNames();
if length(cParNames)<1,return,end

% Create labels for each parameter name
cBoxNames=strcat('Parameter ',cellfun(@num2str,num2cell(1:length(cParNames)),...
    'UniformOutput',false));
cBoxNames=strcat(cBoxNames,': ');  

% Create variables required for prompting function
cBoxTypes=cell(length(cParNames),1);
cBoxTypes(:)={'charedit'};
cAllowed=cell(length(cParNames),1);
cAllowed(:)={''};

% Prompt user for parameter names
cNewParNames=Util_InputWindow('Edit parameter names',...
           'Update parameter names below:',...
           cBoxNames,cBoxTypes,cAllowed,cParNames,true);

% Check that proper strings were added
if ~isempty(cNewParNames)
    vParNames('set',cNewParNames');
    fUpdateGUI();
end

% --- Executes on button press in cmdAddFile.
function cmdAddFile_Callback(hObject, eventdata, handles)
% hObject    handle to cmdAddFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cParNames=vParNames();

% Prompt user for filename
[filename,pathname]=uigetfile({'*.txt','Text files (*.txt)'},...
    'Please select a file','MultiSelect','on');
if ~iscell(filename)&&~ischar(filename)&&filename==0
    return;
elseif ~iscell(filename)
    filename={filename};
end

% Group new filenames together
cFilenames=strcat(pathname,filename)';
cNewFilelist=cell(size(cFilenames,1),length(cParNames)+1);
cNewFilelist(:,1)=cFilenames;
cNewFilelist(:,2:end)={''};

% Add new files to list
fAddFilesToList(cNewFilelist);


function fAddFilesToList(cNewFilelist)

cFilelist=vFilelist();
cFilechars=vFilechars();  

if isempty(cNewFilelist),return,end
cDuplicate={};
cBadFile={};

% Compare # of parameters of original and new filelists
if ~isempty(cFilelist)
    if size(cNewFilelist,2)>size(cFilelist,2)
        Comm_Warn('New files have too many parameters.');
        return
    elseif size(cNewFilelist,2)<size(cFilelist,2)
        nNewColumns=size(cFilelist,2)-size(cNewFilelist,2);
        cNewFilelist(:,(end+1):(end+nNewColumns))={''}; 
    end
end

for i=1:size(cNewFilelist,1)
    sSampleFile=cNewFilelist{i,1};
    
    % Check that file doesn't already exist
    if ~isempty(cFilelist)&&any(strcmp(cFilelist(:,1),sSampleFile))
        cDuplicate{end+1}=sSampleFile;
        %Comm_Alert(sprintf('File already present in file list (%s).',sSampleFile));
        continue
    end

    % Check headerlines and number of channels
    [nNumChan nHeaderLines]=Util_GetFileInfo(sSampleFile);
    if isempty(nNumChan)||isempty(nHeaderLines)
        cBadFile{end+1}=sSampleFile;
        %Comm_Alert(sprintf('File couldn''t be loaded (%s).',sSampleFile));
        continue
    end
    iNewLine=length(cFilechars.name)+1;
    cFilechars.name{iNewLine}=sSampleFile;
    cFilechars.headerLines(iNewLine)=nHeaderLines;
    cFilechars.channels(iNewLine)=nNumChan;

    % Add new file to list variable
    iNewLine=size(cFilelist,1)+1;
    cFilelist(iNewLine,:)=cNewFilelist(i,:);    
end
vFilelist('set',cFilelist);
vFilelist('sort');
vFilechars('set',cFilechars);


% Display to user all errors that occurred
cError={};
if ~isempty(cDuplicate)
    cError{end+1}='The following files have already been added:';
    cError(end+1:end+length(cDuplicate))=cDuplicate;
end
if ~isempty(cBadFile)
    cError{end+1}='The following files could not be loaded:';
    cError(end+1:end+length(cBadFile))=cBadFile;
end
if ~isempty(cError)
    Comm_Warn(cError);
end

% Update table
fUpdateGUI();


function fUpdateGUI()

hdlGUI=fLibrary('hdlGUI');

cParNames=vParNames();
cFilelist=vFilelist();
cFilechars=vFilechars();

% Update column headings
set(hdlGUI.tblFilelist,'ColumnName',{'Filename',cParNames{:}});

% Update table info
set(hdlGUI.tblFilelist,'Data',cFilelist);
temp=cell(1,size(cFilelist,2));
temp(1:end)={'char'};
set(hdlGUI.tblFilelist,'ColumnFormat',temp)
temp=zeros(1,size(cFilelist,2));
temp(2:end)=1;
set(hdlGUI.tblFilelist,'ColumnEditable',logical(temp))

% Update file summary
if ~isempty(cFilelist)
    sLabel=['# files:  ',num2str(size(cFilelist,1))];
else
    sLabel=['# files:  ','-'];
end
set(hdlGUI.txtNumFiles,'String',sLabel);

if ~isempty(cFilelist)&&size(cFilelist,2)>=2
    sLabel=['# missing parameters:  ',num2str(sum(sum(strcmp(cFilelist(:,2:end),''))))];
else
    sLabel=['# missing parameters:  ','-'];
end
set(hdlGUI.txtMissingPars,'String',sLabel);

if isempty(cFilechars.headerLines)
    sLabel=['# headerlines:  ','-'];
elseif any(cFilechars.headerLines~=cFilechars.headerLines(1))
    sLabel=['# headerlines:  ','X'];
else
    sLabel=['# headerlines:  ',num2str(cFilechars.headerLines(1))];
end
set(hdlGUI.txtHeaderLines,'String',sLabel);

if isempty(cFilechars.channels)
    sLabel=['# channels:  ','-'];
elseif any(cFilechars.channels~=cFilechars.channels(1))
    sLabel=['# channels:  ','X'];
else
    sLabel=['# channels:  ',num2str(cFilechars.channels(1))];
end
set(hdlGUI.txtNumChannels,'String',sLabel);

% Enable/disable items as necessary
if isempty(cFilelist)
    set(hdlGUI.cmdRemoveFile,'Enable','off');
    %set(hdlGUI.cmdOK,'Enable','off');  % commented out in V2.3.0 to allow
    %users to clear a filelist
    set(hdlGUI.tblChannels,'Enable','off');
    set(hdlGUI.cmdAddPar,'Enable','off');
    set(hdlGUI.cmdRemovePar,'Enable','off');
    set(hdlGUI.cmdEditNames,'Enable','off');
    set(hdlGUI.tblChannels,'Enable','off');
  
else
    set(hdlGUI.cmdRemoveFile,'Enable','on');
    set(hdlGUI.cmdOK,'Enable','on');
    set(hdlGUI.tblChannels,'Enable','on');
    set(hdlGUI.cmdAddPar,'Enable','on');
    set(hdlGUI.cmdRemovePar,'Enable','on');
    set(hdlGUI.cmdEditNames,'Enable','on');

    if size(cFilelist,2)<2
        set(hdlGUI.cmdRemovePar,'Enable','off');
        set(hdlGUI.cmdEditNames,'Enable','off');
    else
        set(hdlGUI.cmdRemovePar,'Enable','on');
        set(hdlGUI.cmdEditNames,'Enable','on');
    end

    if size(cFilelist,2)>6
        set(hdlGUI.cmdAddPar,'Enable','off');
    else
        set(hdlGUI.cmdAddPar,'Enable','on');
    end
    
   
end

fUpdateChanObjects(cFilelist,cFilechars);


function fUpdateChanObjects(cFilelist,cFilechars)

hdlGUI=fLibrary('hdlGUI');

% Retrieve channel info
ChanInfo=vChanInfo();

% If filelist is empty, clear channel variable and disable table
if isempty(cFilelist)
    vChanInfo('clear'); 
    vChanInfo('updatetable',hdlGUI.tblChannels);
    set(hdlGUI.tblChannels,'Enable','off')

% If filelist's channel # is inconsistent, disable table 
elseif any(cFilechars.channels~=cFilechars.channels(1))
    set(hdlGUI.tblChannels,'Enable','off')
    
% If filelist's channel # does not match variable's number, reset variable
elseif isempty(ChanInfo) || ChanInfo.numChan~=cFilechars.channels(1)
    ChanInfo=vChanInfo('reset',cFilechars,cFilelist{1,1});
    vChanInfo('updatetable',hdlGUI.tblChannels);
    set(hdlGUI.tblChannels,'Enable','on');
    
% Load and enable table
else
    vChanInfo('updatetable',hdlGUI.tblChannels);
    set(hdlGUI.tblChannels,'Enable','on');
end


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4


% --- Executes on button press in checkbox5.
function checkbox5_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox5


% --- Executes on button press in Position.
function Position_Callback(hObject, eventdata, handles)
% hObject    handle to Position (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Position


% --- Executes on button press in cmdRemoveFile.
function cmdRemoveFile_Callback(hObject, eventdata, handles)
% hObject    handle to cmdRemoveFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cmdRemoveFile

hdlGUI=fLibrary('hdlGUI');
cFilelist=vFilelist();
cFilechars=vFilechars();

% Determine which filename is selected in table
temp=get(hdlGUI.tblFilelist,'UserData');
if isempty(temp)
    Comm_Alert('Please select the row(s) of the file(s) that you wish to delete.');
    return
end

% Verify that user wishes to delete the files
sCheck=questdlg('Are you sure you want to remove the selected file(s)?',...
    'Verify removal','Yes, remove','No','No');
if ~strcmp(sCheck,'Yes, remove'),return;end

% Delete the files
nRows=unique(temp(:,1));
cData=get(hdlGUI.tblFilelist,'Data');
for i=1:length(nRows)
    nRow=nRows(i);
    sFilename=cData{nRow,1};

    % Remove file from filelist
    iWhereIsFilename=find(strcmp(cFilelist(:,1),sFilename));
    if isempty(iWhereIsFilename),return,end
    cFilelist(iWhereIsFilename,:)=[];

    % Remove file from characteristics array
    iWhereIsFilename=find(strcmp(cFilechars.name,sFilename));
    if isempty(iWhereIsFilename),return,end
    cFilechars.name(iWhereIsFilename)=[];
    cFilechars.headerLines(iWhereIsFilename)=[];
    cFilechars.channels(iWhereIsFilename)=[];
end

% Reselect same row (or bottom) (not currently possible)

% If no files remain, clear parameter and filelist vars
if size(cFilelist,1)==0
    vFilelist('reset');
    vParNames('reset');
    vFilechars('reset');
    vChanInfo('clear');

% Otherwise copy updated data to variables
else
    vFilelist('set',cFilelist);
    vFilechars('set',cFilechars);
end

% Update GUI
fUpdateGUI;

% --- Executes on button press in cmdCheck.
function cmdCheck_Callback(hObject, eventdata, handles)
% hObject    handle to cmdCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in cmdSMARTfill.
function cmdSMARTfill_Callback(hObject, eventdata, handles)
% hObject    handle to cmdSMARTfill (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cFilelist=vFilelist();

% Call SMART fill for user to select multiple files according to a given
% pattern
if ~isempty(cFilelist)
    nMaxPars=size(cFilelist,2)-1;
    cNewFiles=SMARTfill(nMaxPars);
else
    cNewFiles=SMARTfill();
    nNumPars=size(cNewFiles,2)-1;
    cParNames=strcat('Par',cellfun(@num2str,num2cell(1:nNumPars),...
        'UniformOutput',false));
    vParNames('set',cParNames);    
end

fAddFilesToList(cNewFiles);

% --- Executes on button press in cmdAddPar.
function cmdAddPar_Callback(hObject, eventdata, handles)
% hObject    handle to cmdAddPar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cmdAddPar

cFilelist=vFilelist();
cParNames=vParNames();

% Only allow up to six parameters
if size(cFilelist,2)>6,return;end

% Determine currently selected cell (if there is one)
temp=get(handles.tblFilelist,'UserData');
if isempty(temp),temp=[1,size(cFilelist,2)];end
nCol=unique(temp(:,2));
if size(nCol,1)>1,nCol=[];end
if isempty(nCol)
    nNewColumn=size(cFilelist,2)+1;
else
    nNewColumn=nCol+1;
end

% Add column to filelist
for i=size(cFilelist,2)+1:-1:nNewColumn+1
    cFilelist(:,i)=cFilelist(:,i-1);
end
cFilelist(:,nNewColumn)={''};

% Add new parameter name
nNewName=nNewColumn-1;
for i=length(cParNames)+1:-1:nNewName+1
    cParNames(i)=cParNames(i-1);
end
cParNames{nNewName}='';
for i=1:99
    nCandidateName=['Par',num2str(i)];
    if ~any(strcmp(cParNames,nCandidateName))
        cParNames{nNewName}=nCandidateName;
        break
    end
end
if strcmp(cParNames{nNewName},'')
    Comm_Error('Unique parameter name could not be generated.');
    return;
end

% Update variables
vFilelist('set',cFilelist);
vParNames('set',cParNames);

fUpdateGUI;

% --- Executes on button press in cmdRemovePar.
function cmdRemovePar_Callback(hObject, eventdata, handles)
% hObject    handle to cmdRemovePar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cmdRemovePar

cFilelist=vFilelist();
cParNames=vParNames();

% Do nothing if there are no parameters
if isempty(cParNames),return,end

% Determine currently selected cell (if there is one)
temp=get(handles.tblFilelist,'UserData');
if isempty(temp)||max(temp(:,2))==1
    Comm_Alert('Please select a cell in the parameter column you wish to delete.');
    return
end
nTargetColumns=unique(temp(:,2));
nTargetColumns(nTargetColumns==1)=[];
nTargetNames=nTargetColumns-1;

% Check removal with user
sString=sprintf('"%s"',cParNames{nTargetNames(1)});
for i=2:length(nTargetNames)
   if i<length(nTargetNames)
        sString=sprintf('%s, "%s"',sString,cParNames{nTargetNames(i)});   
   else
       sString=sprintf('%s and "%s"',sString,cParNames{nTargetNames(end)});
   end
end
sCheck=questdlg(sprintf('Are you sure you want to delete the parameter(s) %s?',...
    sString),'Verify delete','Yes, delete','No','No');
if ~strcmp(sCheck,'Yes, delete'),return;end

% Remove column from filelist
cFilelist(:,nTargetColumns)=[];

% Remove parameter name
cParNames(nTargetNames)=[];

% Update variables
vFilelist('set',cFilelist);
if ~isempty(cParNames)
    vParNames('set',cParNames);
else
    vParNames('reset');
end

fUpdateGUI;


% --- Executes when selected cell(s) is changed in tblFilelist.
function tblFilelist_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to tblFilelist (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

% Store selected cell's indices as table's UserData property
set(hObject,'UserData',eventdata.Indices);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Release all global objects

vParNames('clear');
vFilelist('clear');
vFilechars('clear');

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end


% --- Executes when entered data in editable cell(s) in tblFilelist.
function tblFilelist_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to tblFilelist (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% Trim newly edited cell
cData=get(hObject,'Data');
if isempty(cData),return,end
if nargin>1
    sCellData=cData{eventdata.Indices(1),eventdata.Indices(2)};
    sTrimmed=strtrim(sCellData);
    if ~strcmp(sTrimmed,sCellData)
        cData{eventdata.Indices(1),eventdata.Indices(2)}=sTrimmed;
        set(hObject,'Data',cData);
    end
end    

% Update file list 
cFilelist=cData;
vFilelist('set',cFilelist);
%vFilelist('sort');

fUpdateGUI;

% This function holds variables so that they can act as globals for this
% GUI only.
function X=vChanInfo(A,B,C)
% bToUse,cTitles,cSampleData

persistent ChanInfo

X=[];

% Clear variable
if nargin==1 && strcmp(A,'clear')
    % clear all variables
    clear ChanInfo;

% Reset variable using given number of channels
elseif nargin==3 && strcmp(A,'reset')
    cFilechars=B;
    ChanInfo.numChan=cFilechars.channels(1);
    ChanInfo.toUse=true(ChanInfo.numChan,1);
    ChanInfo.titles(1:ChanInfo.numChan)=strcat('Chan',...
        cellfun(@num2str,num2cell(1:ChanInfo.numChan),...
        'UniformOutput',false));
    ChanInfo.sampleData=fGetSampleData(C);
    X=ChanInfo;
    

% Update table using given table handle
elseif nargin==2 && strcmp(A,'updatetable')
    hTable=B;
    cData={''};
    if ~isempty(ChanInfo)
        cData=cell(ChanInfo.numChan,4);
        for i=1:ChanInfo.numChan
            cData{i,1}=i;
            cData{i,2}=ChanInfo.toUse(i);
            cData{i,3}=ChanInfo.titles{i};
            cData{i,4}=ChanInfo.sampleData{i};
        end        
    end
    set(hTable,'Data',cData);
    
elseif nargin==2 && strcmp(A,'isa')
    if ~isempty(B)&&isstruct(B)&&...
      isequal(sort(fieldnames(B)),{'numChan';'sampleData';'titles';'toUse'})
        X=true;
    else 
        X=false;
    end
    
% Set new value for variables
%{
elseif nargin==4 && strcmp(A,'set') && length(A)==length(cTitles) &&...
    (isempty(cSampleData) || length(cSampleData)==length(A))
    ChanInfo.numChan=length(A);
    ChanInfo.toUse=A;
    ChanInfo.titles=B;
    if ~isempty(C)&&length(C)==ChanInfo.numChan
        ChanInfo.sampleData=C;
    end
%}    
% Set new value for variable
elseif nargin==2 && strcmp(A,'set')
    if vChanInfo('isa',B)
        ChanInfo=B;
    else
        fprintf('WARNING:  Bad input to vChanInfo.\n\n');
    end    
% Return variable
elseif nargin==0
    X=ChanInfo;    
else
    fprintf('WARNING:  Unrecognized command to vChanInfo.\n\n');    
end

function X=vFilechars(A,B,C)

persistent Filechars

X=[];

% Clear variable
if nargin==1 && strcmp(A,'clear')
    % clear all variables
    clear Filechars;

% Reset variable using given number of channels
elseif nargin==1 && strcmp(A,'reset')
    Filechars.headerLines=[];
    Filechars.channels=[];
    Filechars.name={};
    X=Filechars;
    
elseif nargin==2 && strcmp(A,'isa')
    if ~isempty(B)&&isstruct(B)&&...
      isequal(sort(fieldnames(B)),{'channels';'headerLines';'name'})
        X=true;
    else 
        X=false;
    end
    
elseif nargin==2 && strcmp(A,'set')
    if vFilechars('isa',B)
        Filechars=B;
    else
        fprintf('WARNING:  Bad input to vFilechars.\n\n');
    end
    
    
% Return variable
elseif nargin==0
    X=Filechars;
else
    fprintf('WARNING:  Unrecognized command to vFilechars.\n\n');
end


function X=vFilelist(A,B,C)

persistent Filelist

X=[];

% Clear variable
if nargin==1 && strcmp(A,'clear')
    % clear all variables
    clear Filelist;

% Reset variable using given number of channels
elseif nargin==1 && strcmp(A,'reset')
    Filelist={};
    X=Filelist;
elseif nargin==1 && strcmp(A,'sort') 
    for i=[1,size(Filelist,2):-1:2]
        [~,nSorted]=Util_AlphaNumSort(Filelist(:,i));
        Filelist=Filelist(nSorted,:);
    end
    
elseif nargin==2 && strcmp(A,'isa')
    if ~isempty(B)&&iscell(B)&&...
        all(all(cellfun(@ischar,B,'UniformOutput',true)))&&...
            size(B,2)<=7;
        X=true;
    else
        X=false;
    end
    
elseif nargin==2 && strcmp(A,'set')
    if vFilelist('isa',B)
        Filelist=B;
    else
        fprintf('WARNING:  Bad input to vFilelist.\n\n');
    end
        
elseif nargin==1 && strcmp(A,'getfilechars')
    
    for i=1:size(Filelist,1)
        sSampleFile=Filelist{i,1};

        % Check headerlines and number of channels
        [nNumChan nHeaderLines]=Util_GetFileInfo(sSampleFile);
        if isempty(nNumChan)||isempty(nHeaderLines)
            nNumChan=NaN;
            nHeaderLines=NaN;
            fprintf(['WARNING:  Headerlines and/or channel number not found for:\n',...
                '          > %s.\n\n'],sSampleFile);            
        end
        X.name{i}=sSampleFile;
        X.headerLines(i)=nHeaderLines;
        X.channels(i)=nNumChan;
    end
    
% Return variable
elseif nargin==0
    X=Filelist;
    
else
    fprintf('WARNING:  Unrecognized command to vFilelist\n\n');
end

function X=vParNames(A,B,C)

persistent ParNames

X=[];

% Clear variable
if nargin==1 && strcmp(A,'clear')
    % clear all variables
    clear ParNames;

% Reset variable using given number of channels
elseif nargin==1 && strcmp(A,'reset')
    ParNames={};
    X=ParNames;
    
% Set value of variable
elseif nargin==2 && strcmp(A,'set')
    if vParNames('isa',B)
        ParNames=B;
    else
        fprintf('WARNING:  Bad input to vParNames.\n\n');
    end
    
% Check whether inputted argument is a list of parameter names
elseif nargin==2 && strcmp(A,'isa')
    if ~isempty(B)&&iscell(B)&&min(size(B))==1&&...
            all(cellfun(@ischar,B,'UniformOutput',true))
        X=true;
    else
        X=false;
    end
    
% Return variable
elseif nargin==0
    X=ParNames;
    
else
    fprintf('WARNING:  Unrecognized command to vParNames\n\n');
end

function cSampleData=fGetSampleData(sSampleFile)

% Load a value for each column of data in the given file
cSampleData={};
fid=fopen(sSampleFile);
if fid~=-1
    [nNumChannels nHeaderLines sDelim sPattern]=...
        Util_GetFileInfo(sSampleFile);
    cSampleData(1:nNumChannels)={''};
    cSampleData=textscan(fid,sPattern,1,'HeaderLines',nHeaderLines,...
        'Delimiter',sDelim);
    % (Empty 'cells' are loaded as cells is cSampleData, which cause errors)
    cSampleData(cellfun(@iscell,cSampleData))={''};
    fclose(fid);
end

% --- Executes when entered data in editable cell(s) in tblChannels.
function tblChannels_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to tblChannels (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)


% Trim edited cell
cData=get(hObject,'Data');
if isempty(cData)||(numel(cData)==1&&isempty(cData{1})),return,end
if nargin>1
    sCellData=cData{eventdata.Indices(1),eventdata.Indices(2)};
    if ischar(sCellData)
        sTrimmed=strtrim(sCellData);
        if ~strcmp(sTrimmed,sCellData)
            cData{eventdata.Indices(1),eventdata.Indices(2)}=sTrimmed;
            set(hObject,'Data',cData);
        end
    end
end
    
% Get table data 
bToUse=logical(cell2mat(cData(:,2)));
cTitles=cData(:,3);
cSampleData=cData(:,4);

% Check that at least one channel is included
if all(~bToUse)
    ChanInfo=vChanInfo();
    for i=1:size(cData,1)
        cData{i,2}=ChanInfo.toUse(i); 
        cData(i,3)=ChanInfo.titles(i);
    end
    set(hObject,'Data',cData);
    Comm_Warn('At least one channel must be included.');

% Check that all channel names are non-blank
elseif any(cellfun(@isempty,cTitles))
    ChanInfo=vChanInfo();
    for i=1:size(cData,1)
        cData{i,2}=ChanInfo.toUse(i); 
        cData(i,3)=ChanInfo.titles(i);
    end
    set(hObject,'Data',cData);
    Comm_Warn('All channels must have a label.');    
    
% Check that all channel names are unique
elseif length(unique(cTitles))<length(cTitles)
    ChanInfo=vChanInfo();
    for i=1:size(cData,1)
        cData{i,2}=ChanInfo.toUse(i); 
        cData(i,3)=ChanInfo.titles(i);
    end
    set(hObject,'Data',cData);
    Comm_Warn('All channel labels must be unique.');    
    
else
    % Update channel variable if no errors
    ChanInfo.numChan=size(cData,1);
    ChanInfo.toUse=bToUse;
    ChanInfo.titles=cTitles;
    ChanInfo.sampleData=cSampleData;
    vChanInfo('set',ChanInfo);
end


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get original window positioning
cPosns=get(hObject,'UserData');
if isempty(cPosns),return,end

% Define minimum, default, and current window size
nDefaultHeight=cPosns.figure1(4);
nDefaultWidth=cPosns.figure1(3);
nMinHeight=nDefaultHeight;
nMinWidth=nDefaultWidth;
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

% Move and resize tables
X=cPosns.tblFilelist;
set(handles.tblFilelist,'Position',[X(1) X(2) X(3)+dX X(4)+dY]);
X=cPosns.tblChannels;
set(handles.tblChannels,'Position',[X(1) X(2) X(3)+dX X(4)]);
X=cPosns.FileColumnWidth;X{1}=X{1}+dX;
set(handles.tblFilelist,'ColumnWidth',X);
X=cPosns.ChanColumnWidth;X{3}=X{3}+dX;
set(handles.tblChannels,'ColumnWidth',X);

% Move and resize other objects
X=cPosns.cmdOK;
set(handles.cmdOK,'Position',[X(1)+dX X(2) X(3) X(4)]);
X=cPosns.cmdCancel;
set(handles.cmdCancel,'Position',[X(1)+dX X(2) X(3) X(4)]);
X=cPosns.pnlFilelistInfo;
set(handles.pnlFilelistInfo,'Position',[X(1)+dX X(2) X(3) X(4)]);
X=cPosns.lblParameters;
set(handles.lblParameters,'Position',[X(1)+0.5*dX X(2) X(3) X(4)])
X=cPosns.cmdAddPar;
set(handles.cmdAddPar,'Position',[X(1)+0.5*dX X(2) X(3) X(4)])
X=cPosns.cmdRemovePar;
set(handles.cmdRemovePar,'Position',[X(1)+0.5*dX X(2) X(3) X(4)])
X=cPosns.cmdEditNames;
set(handles.cmdEditNames,'Position',[X(1)+0.5*dX X(2) X(3) X(4)])
