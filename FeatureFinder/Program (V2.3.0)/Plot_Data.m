% Plot_Data(HANDLES)
%   The Plot_Data function plots data specified by the profile file into 
%   the axis or axes specified by HANDLES.
%   
%   Input arguments:
%       HANDLES - the handle(s) of the axis or axes where data is to be
%           plotted.
%   
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010-2012.

function Plot_Data(hdlPlot)

% Retrieve GUI object information
cObjects=vObjects();

thisProfile=vCurrentProfile();
sProfile=thisProfile.name;

% Setup variable to store information on plot contents
WindowFixedObjects=HandleList;

% If filelist or settings are empty, exit
if isempty(thisProfile.fileList)|isempty(thisProfile.dataSettings)
    return
end

% Alert user that data is being loaded
cla(hdlPlot(1));
axes(hdlPlot(1));
nPos=get(hdlPlot(1),'Position');
nTextMargin=4;
hNote1=text(nTextMargin+2,nPos(4)-1,...
    'LOADING DATA...','Units','pixels','HorizontalAlignment','left',...
    'VerticalAlignment','top','BackgroundColor',[1 1 0.9],...
    'Margin',nTextMargin);
drawnow
%Util_PreventInput(true);
figure(findobj('Tag','figure1'));


% ------------------------
% -- 1.0 Setup function --
% ------------------------

% 1.1 Get plotting options from source file, setup variables
temp=Profile_GetField(cObjects.PlotChecks(:,2),'to_bool');
bNormalize=Profile_GetField('PRE_NORM','to_bool');
bShowRaw=temp(1); 
bShowPreview=temp(2); 
bPreviewFeat=temp(3);
nNumChan=[];
nColor.Raw=[.8 .8 1];
nColor.Proc=[0 0 .8]; nColor.ProcFeat=[.2 .2 .4];
nColor.Prev=[0 .8 0]; nColor.PrevFeat=[0.2 0.4 0.2];
nColor.BL_Proc=[.96 .96 .79]; nColor.Targ_Proc=[.87 .95 1];
nColor.BL_Prev=[.96 .96 .79]; nColor.Targ_Prev=[.87 .95 1];
nMargin=1.1;
nYLim=[];nXLim=[];
Fs=Profile_GetField('FS','to_num');

% 1.2 If no plots selected, give warning and return
if ~(bShowRaw||bShowPreview)
    Comm_Warn('No plotting options selected.  Please select a plotting option and try again');
    cla
    %Util_PreventInput(false);
    return
end

% 1.3 Get parameters of data to plot from profile file
cPlotPar=Profile_GetField(cObjects.PlotMenus(:,2),'to_string');
nChan=thisProfile.getChannel;
sRegion=Profile_GetField(cObjects.PlotRegion(1,2),'to_string');
% 1.4 Find corresponding filename and load data, if requested
sRawFilename=Profile_GetFilename(cPlotPar,1);
if isempty(sRawFilename)
    if isempty(thisProfile.fileList)
        Comm_Help('Tip',['Please click the ''Edit Filelist'' button to ',...
            'associate data files with your profile.']);
    else
        Comm_Warn(['There isn''t a data file associated with the ',...
            'selected parameters.']);
    end    
    cla
    %Util_PreventInput(false);
    return
end
if bShowRaw||bShowPreview
    temp=Data_LoadRaw(sRawFilename);
    if isempty(temp)
        Comm_Warn('Raw data not found (Plot_Data).');
        cla
        %Util_PreventInput(false);
        return
    end
    nRawSamples=[1:size(temp,1)]';
    nRawTime=(nRawSamples-1)/Fs;
    nRawData=temp(:,nChan);
    
    nNumChan=size(nRawData,2);
end

% -------------------
% -- 2.0 Plot data --
% -------------------
hold(hdlPlot(1),'all');

% Alert user that data is being drawn
if ~ishandle(hNote1) %to deal with rapid normalization pressing
    %Util_PreventInput(false);
    return
end
nNotePos=get(hNote1,'Extent');
hNote2=text(nTextMargin+2,nPos(4)-nNotePos(4)-nTextMargin*2,...
    'DRAWING DATA...','Units','pixels',...
    'HorizontalAlignment','left','Margin',nTextMargin,...
    'VerticalAlignment','top','BackgroundColor',[.9 1 0.9]);
%drawnow

% 2.1 If preview features selected, draw window range (on bottom)
if bPreviewFeat
    axis(hdlPlot(1));
    %hdlBL_Prev=rectangle('Position',[0 0 .1 0.1],'FaceColor',...
    %    nColor.BL_Prev,'LineStyle','none','Visible','off');
    hdlBL_Prev=patch([0 1 1 0],[0 0 1 1],nColor.BL_Prev,...
        'EdgeColor','none','Visible','off');
    hdlBL_PrevText=text(0,0,'Baseline','Rotation',90,...
        'HorizontalAlignment','left','VerticalAlignment','top',...
        'Visible','off','FontUnits','pixels','FontSize',11);
    %hdlTarg_Prev=rectangle('Position',[0 0 .1 0.1],'FaceColor',...
    %    nColor.Targ_Prev,'LineStyle','none','Visible','off');
    hdlTarg_Prev=patch([0 1 1 0],[0 0 1 1],nColor.Targ_Prev,...
        'EdgeColor','none','Visible','off');
    hdlTarg_PrevText=text(0,0,'Target','Rotation',90,...
        'HorizontalAlignment','left','VerticalAlignment','top',...
        'Visible','off','FontUnits','pixels','FontSize',11); 
    WindowFixedObjects=WindowFixedObjects.add(...
    [hdlBL_PrevText,hdlTarg_PrevText],...
    {'Y','Y'});
end


% 2.2 If raw data is selected, load and plot 
% | NOTE:  If this step is taking a while, then hold last viewed plot in  |
% | memory so that when the user wants to try different settings, the raw |
% | data needn't be loaded from file each time....   
if bShowRaw        
    if isempty(nYLim),nYLim=zeros(nNumChan,2);end
    if isempty(nXLim),nXLim(1:2)=[min(nRawTime),max(nRawTime)];end
    for iChan=1:nNumChan
        plot(hdlPlot(iChan),nRawTime,nRawData(:,iChan),'Color',nColor.Raw);
        %nYLim(iChan,2)=max([nYLim(iChan,2),max(abs(nRawData(:,iChan)))*nMargin]);
        nYLim(iChan,2)=max(nRawData(:,iChan))*nMargin;
        %nYLim(iChan,1)=min([nYLim(iChan,1),-nYLim(iChan,2)]);        
        nYLim(iChan,1)=min(nRawData(:,iChan));
        if nYLim(iChan,1)>0
            nYLim(iChan,1)=nYLim(iChan,1)/nMargin;
        else
            nYLim(iChan,1)=nYLim(iChan,1)*nMargin;
        end
        % If y-axis limits are identical, space them out
        if nYLim(iChan,1)==nYLim(iChan,2)
            if nYLim(iChan,1)==0
                nManualMargin=1;
            else
                nManualMargin=10^floor(log10(abs(nYLim(iChan,1))));
            end
            nYLim(iChan,1)=nYLim(iChan,1)-nManualMargin;
            nYLim(iChan,2)=nYLim(iChan,2)+nManualMargin;
        end
    end    
end
    
% 2.3 If preview is selected, filter data and plot
% | NOTE:  See above
if bShowPreview
    [nPrevData nPrevTime nFeatures sFeature]=Process_ThisData(nRawData,nRawSamples,Fs); 
    if ~all(isnan(nPrevData))
        if isempty(nYLim),nYLim=zeros(nNumChan,2);end
        if isempty(nXLim)
            nXLim(1:2)=[min(nPrevTime),max(nPrevTime)];
        else
            if min(nPrevTime)<nXLim(1)
                nXLim(1)=min(nPrevTime);
            end
            if max(nPrevTime)>nXLim(2)
                nXLim(2)=max(nPrevTime);
            end
        end
        for iChan=1:nNumChan
            plot(hdlPlot(iChan),nPrevTime,nPrevData(:,iChan),'Color',nColor.Prev);
            nYLim(iChan,2)=max([nYLim(iChan,2),max(nPrevData(:,iChan))*nMargin]);
            temp=min(nPrevData(:,iChan));
            if temp>0
                temp=temp/nMargin;
            else
                temp=temp*nMargin;
            end
            nYLim(iChan,1)=min([nYLim(iChan,1),temp]);        
        end

        % 2.4 If features are selected, display
        if bPreviewFeat       

            nTarget(1)=max(Profile_GetField('FEAT_TARG_FROM','to_num'),min(nRawTime));
            nTarget(2)=min(Profile_GetField('FEAT_TARG_TO','to_num'),max(nRawTime));            
            nBL(1)=max(Profile_GetField('FEAT_BL_FROM','to_num'),min(nRawTime));
            nBL(2)=min(Profile_GetField('FEAT_BL_TO','to_num'),max(nRawTime));  

            if exist('y','var')==0
                y(1:nNumChan)=nYLim(1:nNumChan,2);
            end
            for iChan=1:nNumChan       % multiple channels NOT supported (this line is an artifact)
                x=nXLim(iChan,2);            
                if isempty(nFeatures)
                    sText=[sFeature,': not found'];
                elseif numel(nFeatures)==1                    
                    %sFeatureVal=Util_ToEngNotation(nFeatures(iChan),2);
                    sFeatureVal=num2str(nFeatures);
                    sText=[sFeature,': ',sFeatureVal];
                elseif numel(nFeatures)>10
                    sText=[sFeature,': multiple (>10)'];
                else
                    sText=[sFeature,': ',num2str(nFeatures(1))];
                    for iFeature=2:length(nFeatures)
                        sText=[sText,', ',num2str(nFeatures(iFeature))];
                    end
                end
                %axes(hdlPlot(iChan));
                h=text(x,y(iChan),sText,'HorizontalAlignment','right',...
                    'VerticalAlignment','top','Color',nColor.PrevFeat,...
                    'FontUnits','pixels','FontSize',11,...
                    'Interpreter','none','Parent',hdlPlot(iChan));
                WindowFixedObjects=WindowFixedObjects.add(h,{'XY'});
                temp=get(h,'Extent');
                nHeight=temp(4);
                y(iChan)=y(iChan)-nHeight;   
                
                % Get axis dimensions
                sWasTheUnits=get(hdlPlot(1),'Units');
                set(hdlPlot(1),'Units','pixels');
                temp=get(hdlPlot(1),'Position');
                set(hdlPlot(1),'Units',sWasTheUnits);
                nAxesW=temp(3);nAxesH=temp(4);
                
                % Reshape window boxes
                if diff(nBL)>0 & abs(diff(nYLim(iChan,:)))>0
                    %set(hdlBL_Prev,'Position',[nBL(1) nYLim(iChan,1) diff(nBL) diff(nYLim(iChan,:))],...
                    %    'Visible','on');
                    nBorder=.01; % fraction of y-axis height
                        nYLimTemp(1)=nYLim(iChan,1)+nBorder*diff(nYLim(iChan,:));
                        nYLimTemp(2)=nYLim(iChan,2)-nBorder*diff(nYLim(iChan,:));
                    nPatch=Util_MakeRoundedCorners(nBL(1),nYLimTemp(iChan,1),...
                        diff(nBL),diff(nYLimTemp(iChan,:)),.03,...
                        nAxesW,nAxesH,nXLim(iChan,:),nYLim(iChan,:));
                    
                    set(hdlBL_Prev,'XData',nPatch.X,'YData',nPatch.Y,...
                        'Visible','on');                    
                    nOffsetY=diff(nYLim(iChan,:))*.03;
                    nOffsetX=(nAxesH*(.025-nBorder-0.005))*diff(nXLim(iChan,:))/nAxesW;
                    set(hdlBL_PrevText,'Position',[nBL(1)+nOffsetX nYLim(iChan,1)+nOffsetY],...
                        'Visible','on');     
                end
                if diff(nTarget)>0 & abs(diff(nYLim(iChan,:)))>0                    
                    %set(hdlTarg_Prev,'Position',[nTarget(1) nYLim(iChan,1) diff(nTarget) diff(nYLim(iChan,:))],...
                    %    'Visible','on');
                    % If windows overlap, shrink target
                    if max(min(nTarget),min(nBL))<min(max(nTarget),max(nBL))                        
                        nBorder=.03; % fraction of y-axis height
                        nYLimTemp(1)=nYLim(iChan,1)+nBorder*diff(nYLim(iChan,:));
                        nYLimTemp(2)=nYLim(iChan,2)-nBorder*diff(nYLim(iChan,:));
                        nOffsetY=diff(nYLim(iChan,:))*.05;
                        nOffsetX=(nAxesH*(.045-nBorder-0.005))*diff(nXLim(iChan,:))/nAxesW;
                    else                        
                        nBorder=.01; % fraction of y-axis height
                        nYLimTemp(1)=nYLim(iChan,1)+nBorder*diff(nYLim(iChan,:));
                        nYLimTemp(2)=nYLim(iChan,2)-nBorder*diff(nYLim(iChan,:));
                        nOffsetY=diff(nYLim(iChan,:))*.03;
                        nOffsetX=(nAxesH*(.025-nBorder-0.005))*diff(nXLim(iChan,:))/nAxesW;
                    end
                    nPatch=Util_MakeRoundedCorners(nTarget(1),nYLimTemp(iChan,1),...
                        diff(nTarget),diff(nYLimTemp(iChan,:)),.03,...
                        nAxesW,nAxesH,nXLim(iChan,:),nYLim(iChan,:));
                    
                    set(hdlTarg_Prev,'XData',nPatch.X,'YData',nPatch.Y,...
                        'Visible','on');
                    set(hdlTarg_PrevText,'Position',[nTarget(1)+nOffsetX nYLim(iChan,1)+nOffsetY],...
                        'Visible','on');
                end

            end
        end
    end
end

% Clear information notes
delete(hNote1);
delete(hNote2);

% 2.5 Set limits and add labels
sXLabel='Time (s)';
sYLabel=Profile_GetField('PLOT_YLABEL','to_string');    
if bShowPreview & bNormalize
    if bShowRaw
        sYLabel=[sYLabel(1:end-1),', z-score)'];
    else
        iLastSpace=find(sYLabel==' ',1,'last');
        sYLabel=[sYLabel(1:iLastSpace),'(z-score)'];
    end
end
for iChan=1:nNumChan
    if ~isempty(nXLim)&abs(diff(nXLim))>0
        set(hdlPlot(iChan),'xlim',nXLim);
        fLibrary('OrigXLim',nXLim);
    end
    if ~isempty(nYLim)&abs(diff(nYLim(iChan,:)))>0
        set(hdlPlot(iChan),'ylim',nYLim(iChan,:));
        fLibrary('OrigYLim',nYLim);
    end
    xlabel(hdlPlot(iChan),sXLabel);    
    %ylabel(hdlPlot(iChan),sYLabel);    
end

% temp
fclose all;

% 2.X Add legend (update this if multiple channels supported in future)
% Plot_AddLegend([bShowRaw;bShowProc;bShowPrev],{sLegend.Raw;sLegend.Processed;sLegend.Preview},[nColor.Raw;nColor.Proc;nColor.Prev],'NorthEast');

% 2.6 Store list of window fixed objects
fLibrary('Axes1_WindowFixedObjects',WindowFixedObjects);

% 2.7 Apply zoom
nAxesLim=fLibrary('AxesLim');
WindowFixedObjects=fLibrary('Axes1_WindowFixedObjects');
if ~isempty(WindowFixedObjects)&&~isempty(nAxesLim)
    Plot_Zoom(hdlPlot(1),WindowFixedObjects.handles,...
        WindowFixedObjects.info,nAxesLim);
end

% 2.8 Add filename
set(cObjects.Filename,'String',sRawFilename)
set(cObjects.Filename,'TooltipString',sRawFilename)

% 2.9 Add data limits to file
Profile_SetField('MIN_FILE_SAMPLES',num2str(1));
Profile_SetField('MAX_FILE_SAMPLES',num2str(length(nRawTime)));

%Util_PreventInput(false);

% NOTE: Could have separate Plot_Update function to address NOTE issues above.