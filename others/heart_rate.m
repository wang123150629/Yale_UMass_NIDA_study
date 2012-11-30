function[] = heart_rate()

root_dir = pwd;
data_dir = fullfile(root_dir, 'data');
subject_id = 'P20_048';
subject_session = '2012_08_17-10_15_55';

ecg_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_ECG_clean.csv', subject_session)), 1, 0);
range_x = 2*10e4:2*10e4+10000;
x = ecg_mat(range_x, 7);

Fs = 250;
slide_by = 1;
window_size = 500;
heart_rate_vector = zeros(1, length(x)-window_size);
for s = 1:length(x)-window_size;
	% disp(sprintf('%d:%d', s, s-1+window_size));
	x_window = x(s:s-1+window_size);
	f = abs(fft(x_window));
	[max_volt, max_freq] = max(f(2:end));
	heart_rate_vector(1, s) = max_freq * Fs / length(x_window) * 60;
end
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
plot(heart_rate_vector, 'g-');
ylim([0, 240]);
xlabel('Time(milliseconds)')
ylabel('bpm');

% Loading the summary data
summary_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_summary_clean.csv', subject_session)), 1, 0);

% Loading the RR data
rr_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_RR_clean.csv', subject_session)), 1, 0);
hr_from_rr = 60000 ./ rr_mat;
% hr_from_rr(hr_from_rr < 50) = 0;
hr_from_rr(hr_from_rr > 240) = 0;
sum(hr_from_rr == 0)
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
plot(hr_from_rr, 'b-'); hold on;
plot(summary_mat(:, 7), 'r-');
xlim([1, length(hr_from_rr)]);
ylim([0, 240]);
legend('RR interval HR', 'Zephyr HR', 'Location', 'NorthEast', 'Orientation', 'Horizontal');
xlabel('Time(seconds)')
ylabel('bpm');

qtc_interval = 425 - 676 .* exp(-0.0037 .* rr_mat);
figure(); set(gcf, 'Position', [10, 10, 1200, 800]);
plot(qtc_interval, 'k-');
xlabel('Time(seconds)');
ylabel('QTc interval(milliseconds)');

keyboard

%{
f=fft(x);
[foo, freq]=max(abs(f(2:end))); rate = freq/1000*60

T = 1/Fs;
L = length(x);
t = (0:L-1)*T;
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = 2*abs(fft(x, NFFT)/L);
f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
plot(f, Y(1:NFFT/2+1))
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')
%}

