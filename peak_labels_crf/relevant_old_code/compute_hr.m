function[hr] = compute_hr(approach, ecg_data, varargin)

switch approach
case 'rr'
	assert(length(varargin) == 2);
	peak_idx = varargin{1};
	rr_thresholds = varargin{2};
	hr = RR_based_hr(ecg_data, peak_idx, rr_thresholds);
case 'fft'
	assert(length(varargin) == 1);
	peak_idx = varargin{1};
	hr = FFT_ovlp_based_hr(ecg_data, peak_idx);
case 'sgram'
	assert(length(varargin) == 1);
	peak_idx = varargin{1};
	hr = spectogram_hr(ecg_data, peak_idx);
case 'wavelet'
	hr = wavelet_based_HR(ecg_data);
	keyboard
otherwise
	error('Invalid aproach');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[assigned_hr] = RR_based_hr(ecg_data, peak_idx, rr_thresholds)

raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');

assigned_hr = NaN(size(peak_idx));

[rr, rs] = rrextract(ecg_data', raw_ecg_mat_time_res, rr_thresholds);
rr_start_end = [rr(1:end-1); rr(2:end)-1]';

% Assigning HR for the first chunk prior to the first R peak
rr_intervals = length(rr_start_end(1, 1):rr_start_end(1, 2));
heart_rate = (1000 * 60) ./ (4 .* rr_intervals);
assigned_hr(find(peak_idx < rr_start_end(1, 1))) = heart_rate;
% Assigning HR for all valid chunks
for r = 1:size(rr_start_end, 1)
	rr_intervals = length(rr_start_end(r, 1):rr_start_end(r, 2));
	% If valid RR interval then compute HR; if not then assign previous HR
	if rr_intervals >= 100 & rr_intervals <= 300
		heart_rate = (1000 * 60) ./ (4 .* rr_intervals);
	end
	assigned_hr(find(peak_idx >= rr_start_end(r, 1) & peak_idx < rr_start_end(r, 2))) = heart_rate;
end
% Assigning HR for the last chunk after the last R peak
assigned_hr(find(peak_idx >= rr_start_end(end, 2))) = heart_rate;

assert(~any(isnan(assigned_hr(:))));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[assigned_hr] = FFT_ovlp_based_hr(ecg_data, peak_idx)

nMinutes = 5;
assigned_hr = NaN(size(peak_idx));
raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');
window_size = nMinutes * 60 * raw_ecg_mat_time_res;
filter_size = 1000;
% h = fspecial('average', [1, filter_size]);
h = fspecial('gaussian', [1, filter_size], 150);

NFFT = 2 ^ nextpow2(window_size);
frequencies = (double(raw_ecg_mat_time_res) / 2 * linspace(0, 1, NFFT / 2)); % Vector containing frequencies in Hz
idx = frequencies * 60 >= 50 & frequencies * 60 <= 150;

for p = 1:length(peak_idx)
	start_win = peak_idx(p) - window_size/2;
	end_win = peak_idx(p) + window_size/2-1;

	left_only = false;
	right_only = false;
	if start_win < 0, start_win = 1; right_only = true; end
	if end_win > size(ecg_data, 2), end_win = size(ecg_data, 2); left_only = true; end

	win_data = ecg_data(start_win:end_win);
	ecg_correct = win_data - conv(win_data, h, 'same');
	if right_only, ecg_correct = ecg_correct(1:end-filter_size/2);
	elseif left_only, ecg_correct = ecg_correct(filter_size/2:end);
	else, ecg_correct = ecg_correct(filter_size/2:end-filter_size/2);
	end

	Y = fft(double(ecg_correct), NFFT) / length(ecg_correct);
	amplitudes = 2 * abs(Y(1:(NFFT / 2))); % Vector containing corresponding amplitudes

	[max_a, max_frequency] = max(amplitudes(2:end)); % fetching the index of the maximum amplitude
	heart_rate = frequencies(max_frequency + 1) * 60;
	[max_r, max_freq_range] = max(amplitudes .* idx);
	if max_r/max_a > 0.5
		heart_rate = frequencies(max_freq_range + 1) * 60;
	end
	assigned_hr(p) = heart_rate;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[assigned_hr] = spectogram_hr(ecg_data, peak_idx)

raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');

nMinutes = 2;
window_size = nMinutes * 60 * raw_ecg_mat_time_res;
% Define valid frequency range in bpm
lo = 50;
hi = 200;

valid_peak_idx = find(peak_idx);
assigned_hr = ones(size(valid_peak_idx)) .* -1;

matlabpool open
parfor p = 1:length(valid_peak_idx)
	start_win = valid_peak_idx(p) - window_size/2;
	end_win = valid_peak_idx(p) + window_size/2-1;
	if start_win < 0, start_win = 1; end
	if end_win > size(ecg_data, 2), end_win = size(ecg_data, 2); end

	ecg_correct = ecg_data(start_win:end_win);
	% Compute spectrogram
	[S, f, t] = spectrogram(ecg_correct, chebwin(length(ecg_correct), 400), 0, [], raw_ecg_mat_time_res);
	ind = (60*f>lo) & (60*f<hi);
	Ssub = S(ind,:);
	fsub = f(ind);
	[maxe,maxi] = max(abs(Ssub),[],1);
	assigned_hr(p) = 60*fsub(maxi);
end
matlabpool close

save('gosh_assigned_hr.mat', 'assigned_hr');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[assigned_hr] = old_spectogram_hr(ecg_data, peak_idx)

raw_ecg_mat_time_res = get_project_settings('raw_ecg_mat_time_res');

nMinutes = 2;
window_size = nMinutes * 60 * raw_ecg_mat_time_res;
% Define valid frequency range in bpm
lo = 50;
hi = 200;
filter_size = 10000;
h = fspecial('gaussian', [1, filter_size], 150);
h = h / sum(h);

valid_peak_idx = find(peak_idx);
assigned_hr = ones(size(valid_peak_idx)) .* -1;
matlabpool open
parfor p = 1:length(valid_peak_idx)
	start_win = valid_peak_idx(p) - window_size/2;
	end_win = valid_peak_idx(p) + window_size/2-1;
	if start_win < 0, start_win = 1; end
	if end_win > size(ecg_data, 2), end_win = size(ecg_data, 2); end

	win_data = ecg_data(start_win:end_win);
	ecg_correct = win_data - conv(win_data, h, 'same');
	ecg_correct = ecg_correct(filter_size/2:end-filter_size/2);

	% Compute spectrogram
	[S, f, t] = spectrogram(ecg_correct, chebwin(length(ecg_correct), 400), 0, [], raw_ecg_mat_time_res);
	ind = (60*f>lo) & (60*f<hi);
	Ssub = S(ind,:);
	fsub = f(ind);
	[maxe,maxi] = max(abs(Ssub),[],1);
	assigned_hr(p) = 60*fsub(maxi);
end
matlabpool close

plot(assigned_hr, 'b');
a = load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_sgram_061013.mat');
hold on; plot(a.estimated_hr(valid_peak_idx), 'r');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [beat_rate] = wavelet_based_HR(ecg_data)

baseline_smooth = 250; % 250 samples/sec
sampling_rate = 250; % 250Hz.
window_size = 2^11;

for i=1:floor(length(ecg_data)/window_size)-1
    %%Eliminate baseline drift by smoothing over 5 second windows
    s1=ecg_data(window_size*(i-1)+1:window_size*i)';
    s2=smooth(s1,baseline_smooth);
    ecgsmooth=s1-s2;
    
    %%Wavelet Transform
    [C,L]=wavedec(ecgsmooth,8,'db4');
    [d1,d2,d3,d4,d5,d6,d7,d8]=detcoef(C,L,[1,2,3,4,5,6,7,8]);
    
    %%Denoise
    [thr,sorh,keepapp]=ddencmp('den','wv',ecgsmooth);
    cleanecg=wdencmp('gbl',C,L,'db4',8,thr,sorh,keepapp);
    
    %%Re-construct signal with level 5 approx coeff and a few other detail
    %%coeffs
%     a5=appcoef(C,L,'db4',5);
%     C1=[a5;d5;d4;d3];
%     L1=[length(a5);length(d5);length(d4);length(d3);length(cleanecg)];
%     R_detect_signal=waverec(C1,L1,'db4');
%     R_scale = 4; % re-scale by this after you get the RR interval

    R_detect_signal = cleanecg; % uncomment above if cleaner signal needed
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % extract highest peaks - seems to get R and T. If more peaks are
    % detected, need to fix the code below.
    RTpeakidx = peakfinder(R_detect_signal);
    RTpeaks = R_detect_signal(RTpeakidx);
    
    % partition into two clusters (R and T)
    [RTidx2,RTmeans2] = kmeans(RTpeaks,2,'dist','sqeuclidean');

    % Find R-T-R combos        
    [Rmean, RT_max_idx] = max(RTmeans2);    
    Rpeakidx = RTpeakidx(find(RTidx2==RT_max_idx));
    if RT_max_idx==1 pattern=[1; 2; 1];
    else pattern=[2; 1; 2]; end
        
    RR=[]; RTRidx=[]; RTRval=[];
    for k=1:length(RTidx2)-2
        if (isequal(RTidx2(k:k+2),pattern))
            RTRidx = [RTRidx RTpeakidx(k:k+2)];
            RR = [RR; RTpeakidx(k+2)-RTpeakidx(k)];
        end
    end
    
    RRmed = median(RR);
    
    beat_rate(i,1) = window_size*(i-1)+1;
    beat_rate(i,2) = sampling_rate*60/RRmed;    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    clf; hold on;
    plot(R_detect_signal);
    plot(RTRidx,R_detect_signal(RTRidx),'kx','MarkerSize',10);

    %%%Plot the Orginal Signal and Eliminating Baseline Drift signal
    % subplot(411);plot(s1);title('Orginal Signal');
    % subplot(412);plot(s1-s2);title('Baseline drift Elimination');
    % subplot(413);plot(cleanecg);title('Main Signal');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
plot(beat_rate(:,1),beat_rate(:,2));

%{
if mod(p, 100) == 0
	temp = clock();
	fprintf('p=%d, %d:%d:%0.2f\n', p, temp(4), temp(5), temp(6));
	save('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_big_sgram_061313.mat', 'assigned_hr');
end

% [S, f, t]    = spectrogram(ecg_correct, chebwin(length(ecg_correct), 400), [], [lo:hi]./60, raw_ecg_mat_time_res);
% [maxe, maxi] = max(abs(S),[],1);
% assigned_hr(valid_peak_idx(p)) = 60 * f(maxi);

temp = clock();
fprintf('%d:%d:%0.2f\n', temp(4), temp(5), temp(6));
if mod(p, 100) == 0
	temp = clock();
	fprintf('p=%d, %d:%d:%0.2f\n', p, temp(4), temp(5), temp(6));
end
%}

