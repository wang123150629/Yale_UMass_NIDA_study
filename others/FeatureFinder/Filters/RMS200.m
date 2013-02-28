function nFilteredData=RMS200(nData,Fs)

% Feature description
if nargin==0
    nFilteredData=['A moving average (RMS) filter with a window size ',...
        'of 200 ms and overlap of all but one sample.'];        
    return
end

% Specify window length
nWindow=round(0.200*Fs);

% Check that window length is non-zero (in case of very low sampling rate)
if nWindow==0
    fprintf(['ERROR:  Filter unsuccessful!\n> Window length of ',...
        '0 samples!\n\n']);
    return
end

% Set filter coefficients
b=ones(nWindow,1)/nWindow;
a=1;

% Filter data
nFilteredData=sqrt(filter(b,a,nData.^2));

% Correct for time shift
temp=zeros(length(nFilteredData),1);
temp(ceil(nWindow/2):(end-floor(nWindow/2)))=nFilteredData(nWindow:end);
nFilteredData=temp;