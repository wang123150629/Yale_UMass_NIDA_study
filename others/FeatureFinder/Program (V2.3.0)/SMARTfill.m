function varargout = SMARTfill(varargin)
% SMARTFILL MATLAB code for SMARTfill.fig
%      SMARTFILL, by itself, creates a new SMARTFILL or raises the existing
%      singleton*.
%
%      H = SMARTFILL returns the handle to a new SMARTFILL or the handle to
%      the existing singleton*.
%
%      SMARTFILL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SMARTFILL.M with the given input arguments.
%
%      SMARTFILL('Property','Value',...) creates a new SMARTFILL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SMARTfill_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SMARTfill_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SMARTfill

% Last Modified by GUIDE v2.5 07-Oct-2011 15:05:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SMARTfill_OpeningFcn, ...
                   'gui_OutputFcn',  @SMARTfill_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    try        
        gui_mainfcn(gui_State, varargin{:});
    catch sError
        nNewLineChars=[0 find(double(sError.message)==10) length(sError.message)+1];
        for i=1:length(nNewLineChars)-1
            fprintf('  > %s\n',sError.message((nNewLineChars(i)+1):(nNewLineChars(i+1)-1)));
        end
        fprintf('\n');
        return 
    end
end
% End initialization code - DO NOT EDIT



% --- Executes just before SMARTfill is made visible.
function SMARTfill_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SMARTfill (see VARARGIN)

% Choose default command line output for SMARTfill
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%global cOutput
%global hdlGUI2
%global bSampleFileIsChosen
%global nMaxPars

cOutput={};
hdlGUI2=handles;
bSampleFileIsChosen=false;

% Setup maximum number of parameters
MAXIMUM_PARS = 6;
if isempty(varargin)
    nMaxPars=MAXIMUM_PARS;
elseif length(varargin{1})==1 && isnumeric(varargin{1})
    nMaxPars=min([varargin{1} MAXIMUM_PARS]); 
    if nMaxPars<1
        Comm_Warn('The specified number of parameters is less than 1!');
        return;
    end
else 
    return
end

% Ensure figure and all panels, labels, buttons have light grey background
% and edit boxes have white background
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

% Save variables to library (in place of using globals)
fLibrary('Output',cOutput);
fLibrary('SMARTFillHandles',hdlGUI2);
fLibrary('SampleFileIsChosen',bSampleFileIsChosen);
fLibrary('MaxPars',nMaxPars);

% Setup GUI
fSetupGUI(handles);
fSendMessage('Please select a sample data file by clicking "Select sample file..." below.');

% UIWAIT makes SMARTfill wait for user response (see UIRESUME)
uiwait(handles.figure1);

function fSendMessage(sMessage)

%global hdlGUI2
hdlGUI2=fLibrary('SMARTFillHandles');
set(hdlGUI2.txtMessage,'String',sMessage);


function fSetupGUI(handles)

%global hChar

% Setup mouse action callbacks
set(handles.figure1, 'WindowButtonDownFcn',...
    'SMARTfill(''Down_Click'',gcbf,[],guidata(gcbf))');
set(handles.figure1, 'WindowButtonMotionFcn',...
    'SMARTfill(''Move_Mouse'',gcbf,[],guidata(gcbf))');
set(handles.figure1, 'WindowButtonUpFcn',...
    'SMARTfill(''Up_Click'',gcbf,[],guidata(gcbf))');

% Set size and position of GUI elements
nCharWidth=8;nCharHeight=12;
nLeftOffset=30;nBottomOffset=197;
nNumChars=50;

% Setup filename region
H=nCharHeight;X=nLeftOffset;
Y=nBottomOffset;W=nCharWidth;
for i=nNumChars:-1:1
    hChar(i)=uicontrol('Parent',handles.figure1,'Style','text',...
        'String','','Units','pixels','Position',[(i-1)*W+X Y W H],...
        'BackgroundColor',[1 1 1],'Enable','inactive',...
        'FontUnits','pixels','FontSize',9);
end

fLibrary('hChar',hChar);

% Initialize variables
fLibrary('DragStart',[]);

%{
function fCharPress(hObject,iPressed,hTable,hCount)

bSelectedLetters=fLibrary('SelectedLetters');
nNameOffset=fLibrary('NameOffset');
sSampleFile=fLibrary('SampleFile');
nMaxPars=fLibrary('MaxPars');
hdlGUI2=fLibrary('SMARTFillHandles');

% Test whether pressed key would yield valid file pattern
nToggle=bSelectedLetters*2;nToggle(iPressed+nNameOffset)=1;
[sPattern sGenPattern cExamples]=fGetPattern(sSampleFile,nToggle-bSelectedLetters,nMaxPars);
if isempty(sPattern)
    Comm_Warn(sprintf(['Only %s parameter(s) allowed!  When selecting a single group of',... 
        ' characters, ensure that each selection is adjacent to a',...
        ' previously selected letter.'],num2str(nMaxPars)));
    return
elseif any('\/:'==sSampleFile(iPressed+nNameOffset))
    return
end

% Calculate filelist and update table
cTempFilelist=Util_FileLister(sPattern);
% Remove any files that begin with .
c=1;
while c<=size(cTempFilelist,1)
    [~,sFilename,~]=fileparts(cTempFilelist{c,1});
    if ~isempty(sFilename)&sFilename(1)=='.'
        cTempFilelist(c,:)=[];
    else
        c=c+1;
    end
end
cSMARTFilelist=cTempFilelist;


% Update colours and bSelectedLetters
nColour=get(hObject,'BackgroundColor');
if nColour==[1 1 1]
    set(hObject,'BackgroundColor','r');
    set(hObject,'ForegroundColor',[1 1 1]);
else
    set(hObject,'BackgroundColor',[1 1 1]);
    set(hObject,'ForegroundColor',[0 0 0]);
end
bSelectedLetters=nToggle-bSelectedLetters;


% Update table and OK button
if ~isempty(cSMARTFilelist)
    cTableInfo=cell(length(cExamples),3);
    for i=1:length(cExamples)
        cTableInfo{i,1}=i;
        cTableInfo{i,2}=length(unique(cSMARTFilelist(:,i+1)));
        cTableInfo{i,3}=cExamples{i};
    end
else
    cTableInfo={};
end
set(hTable,'Data',cTableInfo)
set(hCount,'String',num2str(size(cSMARTFilelist,1)))
if size(cSMARTFilelist,1)>0
    set(hdlGUI2.cmdOK,'Enable','on');
else
    set(hdlGUI2.cmdOK,'Enable','off');
end

% Update search string (omit string before wilcards)
if isempty(sGenPattern)
    sGenPattern='No wildcards selected...';
end
set(hdlGUI2.txtSearchString,'String',sGenPattern)

fLibrary('SelectedLetters',bSelectedLetters);
fLibrary('SMARTFilelist',cSMARTFilelist);
%}
% --- Outputs from this function are returned to the command line.
function varargout = SMARTfill_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%global cOutput
cOutput=fLibrary('Output');

varargout{1} = cOutput;

% Clear remaining variables in Library
fLibrary('Output');
fLibrary('SelectedLetters');
fLibrary('NameOffset');
fLibrary('SampleFile');
fLibrary('SMARTFilelist');
fLibrary('SMARTFillHandles');
fLibrary('MaxPars');
fLibrary('SampleFileIsChosen');
fLibrary('hChar');

% The figure can be deleted now
delete(handles.figure1);




% --- Executes on button press in cmdLeft.
function cmdLeft_Callback(hObject, eventdata, handles)
% hObject    handle to cmdLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fSetFilename(-1);

% --- Executes on button press in nRight.
function nRight_Callback(hObject, eventdata, handles)
% hObject    handle to nRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fSetFilename(1);



function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in cmdSelect.
function cmdSelect_Callback(hObject, eventdata, handles)
% hObject    handle to cmdSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%global sSampleFile
%global bSelectedLetters
%global bSampleFileIsChosen

% Prompt user for sample filename
[filename,pathname]=uigetfile({'*.txt','Text files (*.txt)'},...
    'Please select a file');
if filename==0,return,end
bSampleFileIsChosen=true;
fSendMessage('Now, select all parameters in the filename (e.g., Debbie and 2 in "Debbie data/trial2.txt")')
sSampleFile=[pathname,filename];
bSelectedLetters=false(length(sSampleFile),1);

fLibrary('SampleFileIsChosen',bSampleFileIsChosen);
fLibrary('SelectedLetters',bSelectedLetters);
fLibrary('SampleFile',sSampleFile);
fLibrary('NameOffset',0);

fSetFilename();

function fSetFilename(nShift)

%global hChar
%global nNameOffset
%global sSampleFile
%global bSelectedLetters
hChar=fLibrary('hChar');
sSampleFile=fLibrary('SampleFile');
bSelectedLetters=fLibrary('SelectedLetters');
nNameOffset=fLibrary('NameOffset');

if nargin==0
    set(hChar,'String','');
    nNameOffset=max([0,length(sSampleFile)-length(hChar)]);
elseif (nShift+nNameOffset)>=0 && (nShift+nNameOffset)<=length(sSampleFile)-length(hChar)
    nNameOffset=nShift+nNameOffset;
else
    return
end

% Place selected sample file in character boxes
set(hChar,'BackgroundColor',[1 1 1])
set(hChar,'ForegroundColor',[0 0 0]);
for i=1:length(hChar)
    if i+nNameOffset<=length(sSampleFile)
        set(hChar(i),'String',sSampleFile(i+nNameOffset));
        if bSelectedLetters(i+nNameOffset)
            set(hChar(i),'BackgroundColor',[1 0 0]);
            set(hChar(i),'ForegroundColor',[1 1 1]);            
        end
    end
end

fLibrary('NameOffset',nNameOffset);


% --- Executes on button press in cmdCancel.
function cmdCancel_Callback(hObject, eventdata, handles)
% hObject    handle to cmdCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.figure1);

% --- Executes on button press in cmdOK.
function cmdOK_Callback(hObject, eventdata, handles)
% hObject    handle to cmdOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%global cOutput
%global cSMARTFilelist
cSMARTFilelist=fLibrary('SMARTFilelist');

if isempty(cSMARTFilelist)
    Comm_Warn(['Filelist is empty! Please try again or press the ',...
        '"Cancel" button.']);
    return
end

cOutput=cSMARTFilelist;
%clear cSMARTFilelist
fLibrary('Output',cOutput);

close(handles.figure1);

function [sPattern sGenPattern cExamples]=fGetPattern(sSample,bSelected,nMaxPars)

% Initialize counter variables
p = 0; % pattern position counter
w = 0; % wildcard counter
sWildcards='!@#$%^';
cExamples={};
sGenPattern='';

% Loop through sample
for i=1:length(bSelected)
    
    % If letter not selected, include it in sample
    if ~bSelected(i)
        p=p+1;
        sPattern(p)=sSample(i);
    % If letter is the last of a set of selected letters
    elseif i==length(bSelected) || ~bSelected(i+1)
        w=w+1;
        p=p+1;
        if w<=length(sWildcards)&&w<=nMaxPars
            % Replace group by wildcard in pattern
            sPattern(p)=sWildcards(w);
            % Find example string
            for j=i:-1:1
                if (j==1&&bSelected(j)==1)||bSelected(j-1)==0
                    cExamples{w}=sSample(j:i);
                    break
                end
            end
        else
            % Return error if exceeded allowable number of wildcards
            sPattern='';
            return
        end
    end
end

% Create a general file pattern (using a * far all wildcards)
sGenPattern=sPattern;
for i=1:length(sWildcards)
    sGenPattern(sGenPattern==sWildcards(i))='*';
end
iSlashes=find(sGenPattern=='/'|sGenPattern=='\');
iFirstWildcard=find(sGenPattern=='*',1,'first');
if ~isempty(iFirstWildcard)
    iLastPrewildcardSlash=iSlashes(find(iSlashes<iFirstWildcard,1,'last'));
    sGenPattern=['...',sGenPattern(iLastPrewildcardSlash:end)];
else
    sGenPattern='';
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end

% --- Executes during object deletion, before destroying properties.
function cmdCancel_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to cmdCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function txtSearchString_Callback(hObject, eventdata, handles)
% hObject    handle to txtSearchString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSearchString as text
%        str2double(get(hObject,'String')) returns contents of txtSearchString as a double


% --- Executes during object creation, after setting all properties.
function txtSearchString_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSearchString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Down_Click(hObject, eventdata, handles)

% Only proceed if sample file has been chosen
bSampleFileIsChosen=fLibrary('SampleFileIsChosen');
if ~bSampleFileIsChosen,return,end

% Determine character at click point
nThisPoint=get(hObject,'CurrentPoint');
X=nThisPoint(1);
Y=nThisPoint(2);
iChar=fPointToChar(X,Y);
if isempty(iChar),return,end

bSelectedLetters=fLibrary('SelectedLetters');
nNameOffset=fLibrary('NameOffset');
hChar=fLibrary('hChar');

% If character is valid and unselected (e.g., not /\:), or selected,
% then create selection array, add
if fCheckChar(iChar)||bSelectedLetters(iChar+nNameOffset)
    bDragLetters=bSelectedLetters;
    bDragLetters(iChar+nNameOffset)=1-bDragLetters(iChar+nNameOffset);
else
    return
end

% Set colour of all values in selection array (nt: should be able to do
% this without loop?  just make a vector of logicals.. maybe not worth the time..)
iRed=bDragLetters(nNameOffset+1:...
    min(length(bDragLetters),nNameOffset+length(hChar)));
set(hChar(iRed),'BackgroundColor',[1 0 0]);
set(hChar(iRed),'ForegroundColor',[1 1 1]);            
set(hChar(~iRed),'BackgroundColor',[1 1 1]);
set(hChar(~iRed),'ForegroundColor',[0 0 0]);           

% Store starting character and selection array
fLibrary('DragStart',iChar);
fLibrary('DragLetters',bDragLetters);

function Move_Mouse(hObject, eventdata, handles)

% Only proceed if sample file has been chosen and mouse is clicked
bSampleFileIsChosen=fLibrary('SampleFileIsChosen');
if ~bSampleFileIsChosen,return,end
iDragStart=fLibrary('DragStart');
if isempty(iDragStart),return,end

% Determine character at current point
nThisPoint=get(hObject,'CurrentPoint');
X=nThisPoint(1);
Y=nThisPoint(2);
iChar=fPointToChar(X,Y);
if isempty(iChar)
    return
end

bSelectedLetters=fLibrary('SelectedLetters');
nNameOffset=fLibrary('NameOffset');
bPrevDragLetters=fLibrary('DragLetters');

% Determine range of characters between starting and current point
% - exclude trailing end of range if any invalid characters
% - exclude trailing end of range if prior selection type changes
iRange=iDragStart;
if iChar>iDragStart
    for i=iDragStart+1:iChar
        if fCheckChar(i)&&...
                bSelectedLetters(nNameOffset+iDragStart)==bSelectedLetters(nNameOffset+i)
            iRange=[iRange i];
        else
            break
        end        
    end
else
    for i=iDragStart-1:-1:iChar
        if fCheckChar(i)&&...
                bSelectedLetters(nNameOffset+iDragStart)==bSelectedLetters(nNameOffset+i)
            iRange=[i iRange];
        else
            break
        end        
    end
    
end
bDragLetters=bSelectedLetters;
bDragLetters(iRange+nNameOffset)=1-bDragLetters(iRange+nNameOffset);

% If unchanged from the last check, then break
if all(bDragLetters==bPrevDragLetters)
    return
end

% Set colour of all values in selection array
hChar=fLibrary('hChar');
iRed=bDragLetters(nNameOffset+1:...
    min(length(bDragLetters),nNameOffset+length(hChar)));
set(hChar(iRed),'BackgroundColor',[1 0 0]);
set(hChar(iRed),'ForegroundColor',[1 1 1]);            
set(hChar(~iRed),'BackgroundColor',[1 1 1]);
set(hChar(~iRed),'ForegroundColor',[0 0 0]); 

% Store range
fLibrary('DragLetters',bDragLetters);


function Up_Click(hObject, eventdata, handles)

% Only proceed if sample file has been chosen and mouse is clicked
bSampleFileIsChosen=fLibrary('SampleFileIsChosen');
if ~bSampleFileIsChosen,return,end
iDragStart=fLibrary('DragStart');
if isempty(iDragStart),return,end

% Check selection array for errors
fLibrary('DragStart',[]);
bDragLetters=fLibrary('DragLetters');
nNameOffset=fLibrary('NameOffset');
sSampleFile=fLibrary('SampleFile');
nMaxPars=fLibrary('MaxPars');
hdlGUI2=fLibrary('SMARTFillHandles');

% Test whether pressed key would yield valid file pattern
[sPattern sGenPattern cExamples]=fGetPattern(sSampleFile,bDragLetters,nMaxPars);
if isempty(sPattern)
    hChar=fLibrary('hChar');
    bSelectedLetters=fLibrary('SelectedLetters');
    iRed=bSelectedLetters(nNameOffset+1:...
        min(length(bDragLetters),nNameOffset+length(hChar)));
    set(hChar(iRed),'BackgroundColor',[1 0 0]);
    set(hChar(iRed),'ForegroundColor',[1 1 1]);            
    set(hChar(~iRed),'BackgroundColor',[1 1 1]);
    set(hChar(~iRed),'ForegroundColor',[0 0 0]); 
    Comm_Warn(sprintf(['Only %s parameter(s) allowed!  When selecting a single group of',... 
        ' characters, ensure that each selection is adjacent to a',...
        ' previously selected letter.'],num2str(nMaxPars)));    
    return
end

% Calculate filelist and update table
cTempFilelist=Util_FileLister(sPattern);

% Remove any files that begin with .
c=1;
while c<=size(cTempFilelist,1)
    [~,sFilename,~]=fileparts(cTempFilelist{c,1});
    if ~isempty(sFilename)&sFilename(1)=='.'
        cTempFilelist(c,:)=[];
    else
        c=c+1;
    end
end
cSMARTFilelist=cTempFilelist;

% Update table and OK button
hTable=handles.tblParameterInfo;
hCount=handles.txtFilecount;
if ~isempty(cSMARTFilelist)
    cTableInfo=cell(length(cExamples),3);
    for i=1:length(cExamples)
        cTableInfo{i,1}=i;
        cTableInfo{i,2}=length(unique(cSMARTFilelist(:,i+1)));
        cTableInfo{i,3}=cExamples{i};
    end
else
    cTableInfo={};
end
set(hTable,'Data',cTableInfo)
set(hCount,'String',num2str(size(cSMARTFilelist,1)))
if size(cSMARTFilelist,1)>0
    set(hdlGUI2.cmdOK,'Enable','on');
else
    set(hdlGUI2.cmdOK,'Enable','off');
end

% Update search string (omit string before wilcards)
if isempty(sGenPattern)
    sGenPattern='No wildcards selected...';
end
set(hdlGUI2.txtSearchString,'String',sGenPattern)

fLibrary('SelectedLetters',bDragLetters);
fLibrary('SMARTFilelist',cSMARTFilelist);



% This function determines the character position at coordinates X, Y
function iChar=fPointToChar(X,Y)

iChar=[];
hChar=fLibrary('hChar');

% Get position of all characters ([Xmin Ymin Xmax Ymax])
nPos=cell2mat(get(hChar,'Position'));
nPos(:,3)=nPos(:,1)+nPos(:,3);
nPos(:,4)=nPos(:,2)+nPos(:,4);

% Determine which character was clicked
iChar=find(nPos(:,1)<=X&nPos(:,3)>X&nPos(:,2)<=Y&nPos(:,4)>Y);

if length(iChar)>1
    fprintf(['WARNING:  Multiple characters match click.  First ',...
        'character used.\n\n']);
    iChar=iChar(1);
end


% This function determines whether the selected character is acceptible
function isGood=fCheckChar(iChar)

isGood=false;

% Determine character corresponding to provided index
nNameOffset=fLibrary('NameOffset');
sSampleFile=fLibrary('SampleFile');

if ~any('\/:'==sSampleFile(iChar+nNameOffset))
    isGood=true;
end
