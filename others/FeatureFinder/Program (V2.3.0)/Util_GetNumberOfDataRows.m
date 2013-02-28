function nNumRows=Util_GetNumberOfDataRows(sFilename)

nNumRows=[];

% A. Get number of characters in header
[~,nHeaderLines,~,~]=Util_GetFileInfo(sFilename);
nHeaderLength=0;
tic
fid=fopen(sFilename,'r');
for i=1:nHeaderLines
    nHeader=fgets(fid);
    nHeaderLength=nHeaderLength+length(nHeader);
end

% B. Determine overall file size
sInfo=dir(sFilename);
nAllSize=sInfo.bytes;

% C. Generate first length estimate using first row only
sLine=fgets(fid);
nLength=length(sLine);
nLengthEst=(nAllSize-nHeaderLength)/nLength;

% D. Update length estimate using 1% of file's rows (or 10 rows)
nPercEstimate=0.01;
nNumSamples=max([round(nPercEstimate*nLengthEst),10]);
temp=zeros(nNumSamples,1);temp(1)=nLength;nLength=temp;
for c=2:nNumSamples
    % Estimate next sample row's position
    nNextByte=round((nAllSize-nHeaderLength)*c/(nNumSamples+1))+nHeaderLength;
    fseek(fid,nNextByte,-1);
    fgets(fid);
    sLine=fgets(fid);
    if sLine==-1
        % fprintf('NOTE:  Skip @ %0.0f',nNextByte) use for debugging
        continue
    end

    % Revise length estimate based on newest average line length
    nLength(c)=length(sLine);    
end
fclose(fid);

% E. Output estimate
nNumRows=round((nAllSize-nHeaderLength)/mean(nLength));
