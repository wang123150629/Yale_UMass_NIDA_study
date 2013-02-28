% RAWDATA=Data_LoadRaw(FILENAME)
%   This function returns the data from the specified location.
%   
%   Input arguments:
%       FILENAME - the filename where the data is stored.
%   
%   Output arguments;
%       RAWDATA - the data stored at the specified location.
%
% Written by Alex Andrews, 2010-2011.

function nRawData=Data_LoadRaw(sFilename)

persistent iRawData
persistent cRawData

nRawData=[];

% Setup persistent variables.  These store loaded data so that subsequent 
% loads of the same file are faster.
nBufferLen=100; % Number of files to store
if sFilename==-1
    clear cRawData
    clear iRawData
    return
elseif isempty(cRawData)|isempty(iRawData)
    cRawData.Name=cell(nBufferLen,1);
    cRawData.Data=cell(nBufferLen,1);
    iRawData=1;
else
    iMatch=strcmp(cRawData.Name,sFilename);
    if any(iMatch)
        nRawData=cRawData.Data{iMatch};
        return
    else
        iRawData=mod(iRawData,nBufferLen)+1;
    end
end


% Determine file characteristics
[nNumCols nHeaderLines sDelim sPattern]=Util_GetFileInfo(sFilename);
if isempty(nNumCols),return,end

% Load data
fid=fopen(sFilename);
cData=textscan(fid,sPattern,'HeaderLines',nHeaderLines,'Delimiter',sDelim);
fclose(fid);

% Set non-numeric columns to 0 and pad all shorter columns
nLengths=cellfun(@length,cData);
nLongest=max(nLengths);
iIsNumber=cellfun(@isnumeric,cData,'UniformOutput',true);
if ~all(iIsNumber)|~all(nLengths==nLongest)
    if ~all(iIsNumber)
        nIsNotNumber=find(~iIsNumber);
        for i=1:length(nIsNotNumber)
            cData{nIsNotNumber(i)}=zeros(nLongest,1);        
        end
    end
    if any(nLengths~=nLongest)
        for i=1:length(cData)
            if nLengths(i)<nLongest
                nNewVal=zeros(nLongest,1);
                nNewVal(1:length(cData{i}))=cData{i};
                cData{i}=nNewVal;
                %cData{i}=zeropad(cData{i},nLongest);
            end
        end
    end
end
nRawData=cell2mat(cData);
    
% Transfer loaded data to persistent variable
cRawData.Name{iRawData}=sFilename;
cRawData.Data{iRawData}=nRawData;