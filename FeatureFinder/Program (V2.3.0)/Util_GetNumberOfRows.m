function nNumRows=Util_GetNumberOfRows(sFilename)

nNumRows=[];

% Open file and check 
fid=fopen(sFilename,'r');
if fid==-1
    fprintf('ERROR:  %s could not be loaded (Util_GetNumberOfRows)\n\n',...
        sFilename);
    return
end

% Loop through each row
nNumRows=0;
while (fgets(fid)~=-1)
    nNumRows=nNumRows+1;
end
fclose(fid);

end