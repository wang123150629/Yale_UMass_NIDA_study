% OUTPUT_VALS=Util_InputWindow(TITLE,PROMPT,LABELS,TYPE,ALLOWED,DEF,UNIQUE)
%   This function prompts the user for one or more values, using input 
%   methods specified by the input arguments.  This function replaces
%   Util_EditValue and Util_ChooseValue.
%   
%   Input arguments:
%       TITLE - The title of the value selection window, e.g., 'Filter
%           settings'.
%       PROMPT - The instruction to be given to the user, e.g., 'Please select
%           lowpass filter settings:'.
%       LABELS - The name of each value requested from the user, e.g., 
%           {'Order','Cut-off frequency'}.
%       TYPE - A cell of input types ('popmenu','intedit','floatedit',...
%           'charedit').
%       ALLOWED - The allowed values, e.g., {1,250} for a pop-up,
%           [1 240] for a numeric edit box (range), {'hat','moose'} for a character
%           edit box.  An empty input ('') signifies that any value is
%           allowed.
%       DEF - The default values for each input.  The default values must 
%           match ALLOWED, unless the value is '' and input is a pop-up.  In 
%           this case, the default is a blank value.
%       UNIQUE - returned values must be unique (optional, false by
%           default).
%       
%   Output arguments:
%       OUTPUT_VALS - the values chosen by the user
%
%   Example:
%       Util_InputWindow('User Information',...
%           'Please enter your following information:',...
%           {'Name','# of siblings','Hair colour','GPA'},...
%           {'charedit','intedit','popmenu','floatedit'},...
%           {'','',{'blonde','brown','red','black','other'},[0 4]},...
%           {'','','',''},...
%           false);
%
% Written by Alex Andrews, 2010-12.

function cOutputVals=Util_InputWindow(sTitle,sPrompt,cLabels,cType,cAllowed,cDefaults,bUnique)

persistent hFig

% -------------------
% -- 1.0 Setup GUI --
% -------------------

% 1.1 Setup variables and constants
cOutputVals={};

% Don't proceed if window already open
if ishandle(hFig)
    Comm_Warn('Please close all other input windows.');
    return
end

% Check number of input arguments
if nargin==6
    bUnique=false;
elseif nargin~=7
    Comm_Warn('Bad number of inputs (Util_InputWindow).');
    return;
end

% Check input argument types
if ~ischar(sTitle)|~ischar(sPrompt)|~iscell(cLabels)|~iscell(cType)|...
        ~iscell(cAllowed)|~iscell(cDefaults)|~islogical(bUnique)
    Comm_Warn('Bad input types to Util_InputWindow.');
    return
end

% Check input argument sizes
nChoices=length(cLabels);
if length(cType)~=length(cLabels)|length(cAllowed)~=length(cLabels)|...
        length(cDefaults)~=length(cLabels)
    Comm_Warn('Bad input variable sizes to Util_InputWindow.');
    return
end

% If any allowed or default values are numeric, convert
for i=1:length(cAllowed)
   if strcmp(cType{i},'popmenu')|strcmp(cType{i},'charedit')
        if isnumeric(cAllowed{i})
           for j=1:length(cAllowed{i})
               temp{j}=num2str(cAllowed{i}(j));
           end
           cAllowed{i}=temp;
        end
   end
   if isnumeric(cDefaults{i})
       cDefaults{i}=num2str(cDefaults{i});
   end
end
    
% 1.1.1 Define size of each elements
nPromptPos=[0 0 180 20];
nLabelPos(1:nChoices,3)=100; nLabelPos(1:nChoices,4)=20;
nChoicePos(1:nChoices,3)=80; nChoicePos(1:nChoices,4)=20;
nOkayPos=[0 0 60 30];
nCancelPos=[0 0 60 30];
nFontSize=10;

% 1.1.2 Setup margins
nMargins.Prompt=20; % between prompt and first choice
nMargins.Choice=[20 15]; % between label and choice, between rows
nMargins.Buttons=[20 20]; % between buttons, above buttons
nMargins.Border=[25 25 15 25]; % top right bottom left

% 1.1.3 Determine overall dimensions
nInnerWidth=max([nPromptPos(3),...
    nLabelPos(3)+nMargins.Buttons(1)+nChoicePos(3),...
    nOkayPos(3)+nMargins.Buttons(1)+nOkayPos(3)]);
nWidth=sum(nMargins.Border([2,4]))+nInnerWidth;
nRowHeight=max([nLabelPos(1,4),nChoicePos(1,4)]);
nButtonHeight=max([nOkayPos(4),nCancelPos(4)]);
nInnerHeight=nPromptPos(4)+nMargins.Prompt+...
    nChoices*nRowHeight+...
    (nChoices-1)*nMargins.Choice(2)+nMargins.Buttons(2)+...
    nButtonHeight;
nHeight=sum(nMargins.Border([1,3]))+nInnerHeight;

% 1.1.4 Calculate horizontal positions
nPromptPos(1)=(nWidth-nPromptPos(3))/2;
nLabelPos(:,1)=(nWidth-(nLabelPos(1,3)+nMargins.Buttons(1)+nChoicePos(1,3)))/2;
nChoicePos(:,1)=sum(nLabelPos(1,[1,3]))+nMargins.Choice(1);
nOkayPos(1)=(nWidth-(nOkayPos(3)+nMargins.Buttons(1)+nOkayPos(3)))/2;
nCancelPos(1)=sum(nOkayPos([1,3]))+nMargins.Buttons(1);

% 1.1.5 Calculate vertical positions
nPromptPos(2)=nMargins.Border(3)+nButtonHeight+nMargins.Buttons(2)+...
    (nChoices-1)*(nMargins.Choice(2))+...
    nChoices*nRowHeight+nMargins.Prompt;
nLabelPos(:,2)=nMargins.Border(3)+nButtonHeight+nMargins.Buttons(2)+...
    (nChoices-1:-1:0)*(nMargins.Choice(2)+nRowHeight);
nChoicePos(:,2)=nLabelPos(:,2);
nOkayPos(2)=nMargins.Border(3);
nCancelPos(2)=nOkayPos(2);

% 1.2 Create and position figure
nColour=Util_GetSystemColor(0);  
hFig=figure('Visible','off','Units','pixels','DockControls','off',...
    'MenuBar','none','WindowStyle','modal','Resize','off',...
    'Color',nColour);
nPosition=get(hFig,'Position');
nPosition(3)=nWidth;nPosition(4)=nHeight;
set(hFig,'Position',nPosition,'Name',sTitle,'NumberTitle','off');

% 1.3 Add prompt
uicontrol(hFig,'Style','text','String',sPrompt,'Units','pixels',...
    'Position',nPromptPos,'HorizontalAlignment','left',...
    'BackgroundColor',nColour,'FontUnits','pixels','FontSize',nFontSize);

% 1.4 Add edit boxes and labels, set default values
hChoices=zeros(nChoices,1);
bBlankFirst=false(nChoices,1);
for i=1:nChoices
    uicontrol(hFig,'Style','text','String',cLabels{i},'Units','pixels',...
        'Position',nLabelPos(i,:),'HorizontalAlignment','right',...
        'BackgroundColor',nColour,'FontUnits','pixels','FontSize',nFontSize);
    if strcmp(cType{i},'charedit')|strcmp(cType{i},'intedit')|...
            strcmp(cType{i},'floatedit')        
        hChoices(i)=uicontrol(hFig,'Style','edit','Units','pixels',...
            'String',cDefaults{i},'Position',nChoicePos(i,:),...
            'FontUnits','pixels','FontSize',nFontSize,'BackgroundColor',nColour);
    elseif strcmp(cType{i},'popmenu')
        hChoices(i)=uicontrol(hFig,'Style','popupmenu','Units','pixels',...
            'Position',nChoicePos(i,:),'FontUnits','pixels',...
            'FontSize',nFontSize);        
        if strcmp(cDefaults{i},'')&~strcmp(cAllowed{i},'')
            bBlankFirst(i)=true;
            set(hChoices(i),'String',{'',cAllowed{i}{:}});
            set(hChoices(i),'Value',1);
        else
            set(hChoices(i),'String',cAllowed{i});
            nVal=find(strcmp(cAllowed{i},cDefaults{i}),1);
            if ~isempty(nVal)
                set(hChoices(i),'Value',nVal);
            else
                fprintf(['ERROR:  Default value (%s) not available ',...
                    '(Util_InputWindow).\n\n'],cDefaults{i});
                delete(hFig);
                return
            end                    
        end
    else
        fprintf('ERROR:  Bad input type (%s) to Util_InputWindow.\n\n',...
            cType{i});
        delete(hFig);
        return
    end
end

% 1.5 Add button for selection and button to cancel
uicontrol(hFig,'Style','pushbutton','String','OK','Units','pixels',...
    'Position',nOkayPos,'Callback',{@fOK,hFig,hChoices,bUnique,bBlankFirst,cType,cAllowed,cLabels},...
    'FontUnits','pixels','FontSize',nFontSize);
uicontrol(hFig,'Style','pushbutton','String','Cancel','Units','pixels',...
    'Position',nCancelPos,'Callback',{@fCancel,hFig},...
    'FontUnits','pixels','FontSize',nFontSize);
vOutputVals('set',cOutputVals);

% 1.6 Make figure visible
set(hFig,'Visible','on')
drawnow
waitfor(hFig)

% 1.7 Retrieve output value
cOutputVals=vOutputVals();
vOutputVals('clear');
    

% -------------------------
% -- 2.0 Process results --
% -------------------------

% 2.1 If OK pressed, return selection
function fOK(~,~,hFig,hChoices,bUnique,bBlankFirst,cType,cAllowed,cLabels)

cOutputVals=cell(length(hChoices),1);

% Retrieve inputted values
for i=1:length(hChoices)
    sStyle=get(hChoices(i),'Style');
    % If an edit box, retrieve contents
    if strcmp(sStyle,'edit')
        if strcmp(cType{i},'intedit')|strcmp(cType{i},'floatedit')
            cOutputVals{i}=str2double(get(hChoices(i),'String'));
        elseif strcmp(cType{i},'charedit')
            cOutputVals{i}=strtrim(get(hChoices(i),'String'));
        end
    % If a pop-up menu, retrieve current selection
    elseif strcmp(sStyle,'popupmenu')    
        nTemp=get(hChoices(i),'Value');
        sTemp=get(hChoices(i),'String');
        if nTemp==1&bBlankFirst(i)
            Comm_Warn(['Please select a value for the ',cLabels{i},...
                ' pop-up menu.']);
            return
        end
        cOutputVals{i}=sTemp{nTemp};
    else
        fprintf(sprintf(['ERROR:  Unexpected uicontrol style (%s) ',...
            '(Util_InputWindow).\n\n'],sStyle));
    end
end

vOutputVals('set',cOutputVals);

if fCheckValues(bUnique,cType,cAllowed,cLabels)
    delete(hFig);
else
    vOutputVals('set',{});
end

function bOK=fCheckValues(bUnique,cType,cAllowed,cLabels)

bOK=false;
cOutputVals=vOutputVals();

for i=1:length(cType)
    switch cType{i}
        % Check that integer edit boxes contain integer 
        % values within allowed range
        case 'intedit'
            if isempty(cOutputVals{i})|isnan(cOutputVals{i})
                Comm_Warn(sprintf('Please enter a valid, numeric ''%s'' value.',cLabels{i}));
                return
            end           
            if round(cOutputVals{i})~=cOutputVals{i}
                Comm_Warn(['Please ensure that the ''',cLabels{i},...
                    ''' value is an integer.']);
                return
            else
                if ~isempty(cAllowed{i}) 
                    if cOutputVals{i}<cAllowed{i}(1)|cOutputVals{i}>cAllowed{i}(2)
                        Comm_Warn(sprintf(['Please ensure that the ''%s'' ',...
                            'value lies within the range %0.0f-%0.0f.'],...
                            cLabels{i},ceil(cAllowed{i}(1)),floor(cAllowed{i}(2))));
                        return
                    end
                end
            end
        
        % Check that float edit boxes contain float values 
        % within allowed range
        case 'floatedit'
            if isempty(cOutputVals{i})|isnan(cOutputVals{i})
                Comm_Warn(sprintf('Please enter a valid, numeric ''%s'' value.',cLabels{i}));
                return
            end           
            if ~isempty(cAllowed{i}) 
                if cOutputVals{i}<cAllowed{i}(1)|cOutputVals{i}>cAllowed{i}(2)
                    Comm_Warn(sprintf(['Please ensure that the ''%s'' ',...
                        'value lies within the range %0.0f-%0.0f.'],...
                        cLabels{i},cAllowed{i}(1),cAllowed{i}(2)));
                    return
                end
            end      
            
        % Check that character edit boxes contain a char input 
        % of allowed values
        case 'charedit'
            if isempty(cOutputVals{i})
                Comm_Warn(sprintf('Please enter a ''%s'' value.',cLabels{i}));
                return
            end
            if ~isempty(cAllowed{i}) 
                if ~any(strcmp(cAllowed{i},cOutputVals{i}))
                    Comm_Warn(sprintf('Please enter a valid ''%s'' value.',cLabels{i}));
                    return
                end
            end
    end
end

% Ensure inputs are unique
if bUnique && length(unique(cOutputVals))<length(cOutputVals)
    Comm_Warn('Parameter names must be unique.');
    return;
end

bOK=true;


% 2.2 If 'cancel' selected, return empty value
function fCancel(~,~,hFig)

vOutputVals('set',{});

delete(hFig);


function X=vOutputVals(A,B,C)

persistent OutputVals

X=[];

% Clear variable if requested
if nargin==1 && strcmp(A,'clear')
    clear OutputVals
% Set variable if requested
elseif nargin==2 && strcmp(A,'set')
    OutputVals=B;
% Retrieve variable if requested
elseif nargin==0
    X=OutputVals;
% If command not recognized, alert user
else
    fprintf('WARNING:  Unrecognized command to vOutputVals.\n\n');
end