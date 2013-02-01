function nFeature=TargetSDHR(nData,Fs,nBL_Range,nTarg_Range)

% Feature description
if nargin==0
    nFeature='The standard deviation of the target window heart rate, calculated using the positive peaks.';        
    return
end

nData=nData(nTarg_Range);

% Set each pt to -1, 0, or 1 depending on movement
nMove=diff(nData);
nMove(nMove>0)=1;
nMove(nMove<0)=-1;        

% Find sharp peaks
iPeaks=[0;diff(nMove)==-2;0];

% Find peaks of width 2
W=2;
nWidth2=[zeros(W-1,1);nMove((W+1):end)-nMove(1:end-W);zeros(W-1,1)];
iPeaks=iPeaks|[nMove==0&nWidth2==-2;0];

% Find peaks of width 3-–8
for j=3:8
    for i=1:length(nMove)-j    
        if all(nMove(i:i+j)==[1;zeros(j-1,1);-1])
            iPeaks(i+1)=1;
        end
    end
end

% Filter out those peaks with negative amplitudes
iPeaks=find(iPeaks);
iPeaks(nData(iPeaks)<=0)=[];

nHR=60./diff(iPeaks/Fs);
nTime=mean([iPeaks(1:end-1),iPeaks(2:end)]')/Fs;

nFeature=std(nHR);