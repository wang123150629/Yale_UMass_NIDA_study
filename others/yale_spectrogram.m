function[] = yale_spectrogram(ecg_data)

%Set window length
WL=10000;

%Define valid frequency range in bpm
lo  = 50;
hi  = 200;

%Define low-pass Gaussian filter over window
sigma  = WL/6.5;
h = normpdf(1:WL,WL/2,sigma);
h = h/sum(h);

%Filter signal and remove low frequency component
ecgf        = conv(ecg_data,h,'same');
ecg_correct = ecg_data(WL/2:end-WL/2) - ecgf(WL/2:end-WL/2); 

%Compute spectrogram
[S,f,t]     = specgram(ecg_correct,WL,250,chebwin(WL,400),WL*0.95);

%Extract part of spectrogram in valid frequency range
ind = (60*f>lo) & (60*f<hi);
Ssub = S(ind,:);
fsub = f(ind);
[maxe,maxi] = max(abs(Ssub),[],1);
maxf = 60*fsub(maxi);

%Display spectrogram for valid frequency interval
figure(1);clf;
imagesc(t/60,60*fsub,abs(Ssub))
set(gca,'YDir','normal')
xlabel('Time')
ylabel('Frequency')
title('Spectrogram')

%Display plot of maximum energy
figure(2);clf
plot(t/60,maxf)
ylim([lo,hi])
xlabel('Time')
ylabel('Frequency')
title('Dominant Frequency')

keyboard

%{
function[] = yale_spectrogram(ecg_data)

%Set window length
WL=10000;

%Define valid frequency range in bpm
lo  = 50;
hi  = 200;

%Define low-pass Gaussian filter over window
sigma  = WL/6.5;
h = normpdf(1:WL,WL/2,sigma);
h = h/sum(h);

%Filter signal and remove low frequency component
ecgf        = conv(ecg_data,h,'same');
ecg_correct = ecg_data(WL/2:end-WL/2) - ecgf(WL/2:end-WL/2); 

%Compute spectrogram
[S,f,t]     = spectrogram(ecg_correct, chebwin(WL, 400), WL*0.95, [50:200]./60, 250);
%Extract part of spectrogram in valid frequency range
[maxe,maxi] = max(abs(S),[],1);
maxf = 60*f(maxi);

keyboard

%}
