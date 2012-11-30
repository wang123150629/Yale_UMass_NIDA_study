function[] = fft_trial(type)

switch type
case 1
	n = [0:29];
	x = cos(2*pi*n/10);
	figure(); plot(n, x);

	N1 = 64;
	N2 = 128;
	N3 = 256;

	X1 = abs(fft(x,N1));
	X2 = abs(fft(x,N2));
	X3 = abs(fft(x,N3));

	F1 = [0 : N1 - 1]/N1;
	F2 = [0 : N2 - 1]/N2;
	F3 = [0 : N3 - 1]/N3;

	figure();
	subplot(3,1,1); plot(F1,X1,'-x'),title('N = 64'),axis([0 1 0 20]);
	subplot(3,1,2); plot(F2,X2,'-x'),title('N = 128'),axis([0 1 0 20]);
	subplot(3,1,3); plot(F3,X3,'-x'),title('N = 256'),axis([0 1 0 20]);

case 2
	Fs = 1000;                    % Sampling frequency
	T = 1/Fs;                     % Sample time
	L = 1000;                     % Length of signal
	t = (0:L-1)*T;                % Time vector
	% Sum of a 50 Hz sinusoid and a 120 Hz sinusoid
	x = 0.7*sin(2*pi*50*t) + sin(2*pi*120*t); 
	figure(); plot(0:L-1, x);
	y = x + 2*randn(size(t));     % Sinusoids plus noise
	figure(); plot(Fs*t(1:50),y(1:50))
	title('Signal Corrupted with Zero-Mean Random Noise')
	xlabel('time (milliseconds)')

	NFFT = 2^nextpow2(L); % Next power of 2 from length of y
	Y = fft(y,NFFT)/L;
	f = Fs/2*linspace(0,1,NFFT/2+1);

	% Plot single-sided amplitude spectrum.
	plot(f,2*abs(Y(1:NFFT/2+1)))
	title('Single-Sided Amplitude Spectrum of y(t)')
	xlabel('Frequency (Hz)')
	ylabel('|Y(f)|')

case 3
	n = [0:29];
	L = length(n);
	x = cos(2*pi*n/10);
	figure(); plot(n, x);

	NFFT = 2^nextpow2(L);
	X1 = 2 * abs(fft(x, NFFT) / L);
	F1 = linspace(0,1,NFFT);

	figure();
	plot(F1, X1,'-x');

case 4
	root_dir = pwd;
	data_dir = fullfile(root_dir, 'data');
	subject_id = 'P20_048';
	subject_session = '2012_08_17-10_15_55';
	ecg_mat = csvread(fullfile(data_dir, subject_id, subject_session, sprintf('%s_ECG_clean.csv', subject_session)), 1, 0);
	x = ecg_mat(10^6:10^6+1000, 7);

	% f=fft(x);
	% [foo, freq]=max(abs(f(2:end))); rate = freq/1000*60

	Fs = 250;
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

	keyboard
end

