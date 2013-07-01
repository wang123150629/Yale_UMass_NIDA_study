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

