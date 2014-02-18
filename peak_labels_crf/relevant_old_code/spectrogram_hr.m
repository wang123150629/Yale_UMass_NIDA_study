function[] = spectrogram_hr()

load('ecg_data.mat');
load('peak_idx.mat');
compute_hr(ecg_data, peak_idx)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[] = compute_hr(ecg_data, peak_idx)

raw_ecg_mat_time_res = 250;
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

keyboard

