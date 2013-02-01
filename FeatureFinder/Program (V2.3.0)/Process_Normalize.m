% NORM=Process_Normalize(DATA,PARAMS,NORM_PARAMS)
%   This function normalizes data across the parameters specified in
%   NORM_PARAMS.  For example, if NORM_PARAMS=[1 2] and the first two
%   parameters for the loaded profile were subject and channel, then the
%   data would be normalized across subject and channel; therefore, the 
%   mean of all data with subject and channel matching the given data would 
%   be 0, and the standard deviation 1.
%   
%   Input arguments:
%       DATA - the data to be normalized
%       PARAMS - parameters of the given data
%       NORM_PARAMS - a list of parameters to normalize by 
%
%   Output arguments:
%       NORM - normalized data
%       
% Written by Alex Andrews, 2011?2012.

function nNorm=Process_Normalize(nData,cParams,nNormParams)

nNorm=[];

% clear cNormStats is requested
if nData==-1
    %clear cNormStats
    %clear cNormFiltPars
    fprintf('NOTE:  Redundant command sent to Process_Normalize.\n\n');
    return
end

% Check whether parameter list contains all normalization parameters
if min(nNormParams)<1|max(nNormParams)>length(cParams)|...
        isempty(cParams(max(nNormParams)))
    fprintf(['NOTE:  Parameter list sent to Process_Normalize doesn''t ',...
        'contain normalization parameters.\n\n']);
    return
end



% Retrieve GUI object information
cObjects=vObjects();
thisProfile=vCurrentProfile();
sProfile=thisProfile.name;
nNumChans=thisProfile.chanInfo.numChan;
nChan=thisProfile.getChannel;

% ---------------------------------------
% -- 1.0 Load normalization statistics --
% ---------------------------------------

% 1.1 Initialize variables
nMean=[]; nSD=[]; 
if isempty(thisProfile.normInfo)
    thisProfile.normInfo=cell(nNumChans,1);
end

% 1.2 If normalization stats don't exist, load file (if poss.)
if isempty(thisProfile.normInfo{nChan})    
    
    % Create variables that house all possibilities for each norm
    % parameter, and the number of each
    cParamList=cell(length(nNormParams),1);
    nNumParams=zeros(length(nNormParams),1);
    for i=1:length(nNormParams)
        cParamList{i}=get(cObjects.PlotMenus{nNormParams(i),1},'String');
        nNumParams(i)=length(cParamList{i});
    end
    
    % Create a variable that will house mean and SD for each combination of
    % normalization parameters
    cNormStats=cell(prod(nNumParams),length(nNormParams)+2);
    cNormStats(:,end-1:end)={NaN};
    % Fill in all parameter combinations;
    for i=1:length(nNormParams)
        if i<length(nNormParams)
            nDuplicates=prod(nNumParams(i+1:end));
        else
            nDuplicates=1;
        end
        if i>1
            nReps=prod(nNumParams(1:i-1));
            iOffset=nNumParams(i);
        else
            nReps=1;
            iOffset=0;
        end
        for r=1:nReps                
            for j=1:nNumParams(i)
                iStart=(j-1)*nDuplicates+1+iOffset*(r-1);
                iEnd=j*nDuplicates+iOffset*(r-1);
                cNormStats(iStart:iEnd,i)=cParamList{i}(j);
            end
        end
    end
    % Create a cell to house filtering information for each parameter
    % combination
    cNormFiltPars=cell(size(cNormStats,1),1);
    
else
    cNormStats=thisProfile.normInfo{nChan}.normStats;
    cNormFiltPars=thisProfile.normInfo{nChan}.normFiltPars;
end

% 1.3 Find index of current file
iThisFile=ones(size(cNormStats,1),1);
for i=1:length(nNormParams)
    iThisFile=iThisFile&strcmp(cNormStats(:,i),cParams(nNormParams(i)));
end

% 1.4 Determine whether filtering parameters have changed
cFiltPars=Profile_GetField(cObjects.FilterFields,'to_string');
if ~isempty(cNormFiltPars(iThisFile))&...
    length(cFiltPars)==length(cNormFiltPars{iThisFile})&...
    all(strcmp(cNormFiltPars{iThisFile},cFiltPars))

    % 1.5 Determine whether mean and SD exist for given parameters
    if ~isnan(cNormStats{iThisFile,end-1})
        nMean=cNormStats{iThisFile,end-1};
        nSD=cNormStats{iThisFile,end};
    end
end


% -------------------------------------
% -- 2.0 Calc. mean and SD (if nec.) --
% -------------------------------------

% 2.1 Load filelist and norm. filename
if isempty(nMean)|isempty(nSD)
    cFilelist=thisProfile.fileList;
    
% 2.2 Determine all files in the profile with matching norm. parameters
    iFiles=ones(size(cFilelist,1),1);
    for i=1:length(nNormParams)
        iFiles=iFiles&strcmp(cFilelist(:,i+1),cParams(nNormParams(i)));
    end

% 2.3 Load each file and determine mean, SD and # of points for each
    iFiles=find(iFiles);
    h=waitbar(0,'Calculating normalization statistics...','WindowStyle','modal');
    for i=1:length(iFiles)
        sRawFilename=cFilelist{iFiles(i),1};
        temp=Data_LoadRaw(sRawFilename);    
        nOtherData=temp(:,nChan);
        
        % Filter data
        nOtherData=Process_Filter(sProfile,nOtherData);
        
        % Calculate stats
        nAllMeans(i)=mean(nOtherData);
        nAllSDs(i)=std(nOtherData);
        nLengths(i)=length(nOtherData);
        clear nOtherData
        if ~ishandle(h)
            Comm_Alert('Normalization interrupted!');
            return
        else
            waitbar(i/length(iFiles),h)
        end
    end
    if ~ishandle(h)
        Comm_Alert('Normalization interrupted!');
        return
    else
        close(h);
    end

% 2.4 Combine estimates and store in persistent variable & file (write
% filename to file if sNormFile is empty)
    [nMean nSD]=fGroupStats(nAllMeans,nAllSDs,nLengths);
    cNormStats{iThisFile,end-1}=nMean;
    cNormStats{iThisFile,end}=nSD;
    cNormFiltPars{iThisFile}=cFiltPars;
end
thisProfile.normInfo{nChan}.normStats=cNormStats;
thisProfile.normInfo{nChan}.normFiltPars=cNormFiltPars;
vCurrentProfile('set_value',thisProfile);

% ------------------------
% -- 3.0 Normalize data --
% ------------------------

% 3.1 Subtract group mean and divide by group standard deviation
nNorm=(nData-nMean)./nSD;

% --------------------
% -- A1 Group Stats --
% --------------------
function [nGroupMean nGroupSD]=fGroupStats(nMeans,nSDs,nLengths)

nGroupMean=sum(nLengths.*nMeans)/sum(nLengths);
nGroupSD=sqrt(sum(nLengths.*(nSDs.^2+(nMeans-nGroupMean).^2))/sum(nLengths));
% note that this is slightly different than taking the SD
% of all data records combined as many more SD estimates
% are taken 