function[train_alpha, ecg_train_Y, tr_idx, test_alpha, ecg_test_Y, ts_idx, hr_bins] =...
						load_hr_ecg(first_baseline_subtract, sparse_code_peaks, variable_window,...
						normalize, add_height, add_summ_diff, add_all_diff, subject_id, lambda)

results_dir = get_project_settings('results');

dimm = 1;
window_size = 25;
tr_partition = 50;
uniform_split = true;
nDictionayElements = 100;
nIterations = 1000;
filter_size = 10000;
h = fspecial('gaussian', [1, filter_size], 150);
h = h / sum(h);

% New file : Six labels P, Q, R, S, T, U - Unknown
load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_new_labels.mat', subject_id)));

% Reading off data from the interface file
ecg_raw = labeled_peaks(1, :);

if first_baseline_subtract
	% Performing baseline correction
	ecg_data = ecg_raw - conv(ecg_raw, h, 'same');
else
	ecg_data = ecg_raw;
end

ecg_data = ecg_data(filter_size/2:end-filter_size/2);

peak_idx = labeled_peaks(2, :) > 0;
peak_idx = peak_idx(filter_size/2:end-filter_size/2);
peak_idx(1:window_size) = 0;
peak_idx(end-window_size:end) = 0;

labeled_idx = labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100;
labeled_idx = labeled_idx(filter_size/2:end-filter_size/2);
labeled_idx(1:window_size) = 0;
labeled_idx(end-window_size:end) = 0;

peak_labels = labeled_peaks(3, :);
peak_labels = peak_labels(filter_size/2:end-filter_size/2);

% Finding which of those peaks are in fact hand labelled
labeled_peaks_idx = peak_idx & labeled_idx;

estimated_hr = ones(size(ecg_data)) * -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Computing the HR for each of the peaks (NOTE: Now all peaks are associated with a HR; NOT just labelled peaks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This mat holds the new range 70 to 140
load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_bl_subtract_sgram_071313.mat');
% This mat holds the old range 50 to 200
% load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_bl_subtract_sgram_062113.mat');

% estimated_hr(peak_idx) = compute_hr('rr', ecg_data, peak_idx, subject_profile.events{event}.rr_thresholds);
% estimated_hr(peak_idx) = compute_hr('fft', ecg_data, peak_idx);
% load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_fft_053013.mat');
% estimated_hr(peak_idx) = assigned_hr;
% load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_sgram_061013.mat');
% estimated_hr = compute_hr('sgram', ecg_data, peak_idx);
% estimated_hr = compute_hr('wavelet', ecg_data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
estimated_hr(peak_idx) = assigned_hr;

if uniform_split
	nBins = 3;
	tmp_valid_hr = estimated_hr(estimated_hr > 0);
	binned_hr = ntile_split(tmp_valid_hr, nBins);
	for b = 1:nBins
		hr_bins(b, :) = [min(tmp_valid_hr(binned_hr{b})), max(tmp_valid_hr(binned_hr{b}))];
	end
else
	hr_bins = [50, 99; 100, 119; 120, 1000];
end

param = struct();
if sparse_code_peaks
	unlabeled_idx = find(peak_idx - labeled_idx);
	assert(~isempty(unlabeled_idx));
	unlabeled_idx = [unlabeled_idx - window_size; unlabeled_idx + window_size];
	unlabeled_idx = floor(linspaceNDim(unlabeled_idx(1, :), unlabeled_idx(2, :), window_size*2+1));
	ecg_learn = ecg_data(unlabeled_idx)';
	if variable_window
		ecg_learn = window_and_interpolate(ecg_learn, floor(estimated_hr(find(peak_idx - labeled_idx))), window_size);
	end
	if normalize
		ecg_learn = bsxfun(@rdivide, bsxfun(@minus, ecg_learn, mean(ecg_learn, dimm)), std(ecg_learn, [], dimm));
		% ecg_learn = bsxfun(@minus, ecg_learn, mean(ecg_learn, dimm));
	end
	param.K = nDictionayElements;  % learns a dictionary with 100 elements
	param.iter = nIterations;  % let us see what happens after 1000 iterations
	param.lambda = lambda;
	param.numThreads = 4; % number of threads
	param.batchsize = 400;
	param.approx = 0;
	param.verbose = false;

	D = mexTrainDL(ecg_learn, param);
end

for hr1 = 1:size(hr_bins, 1)
	% Training instances. Finding which of the hand labelled peaks fall within the valid HR range
	valid_hr_idx = estimated_hr >= hr_bins(hr1, 1) & estimated_hr <= hr_bins(hr1, 2);
	valid_hr_idx = find(valid_hr_idx & labeled_peaks_idx);

	% No permutation
	tr_idx{hr1} = valid_hr_idx(1:floor(length(valid_hr_idx) * tr_partition / 100));
	train_win_idx = [tr_idx{hr1} - window_size; tr_idx{hr1} + window_size];
	train_win_idx = floor(linspaceNDim(train_win_idx(1, :), train_win_idx(2, :), window_size*2+1));
	ecg_train = ecg_data(train_win_idx)';

	ts_idx{hr1} = valid_hr_idx(floor(length(valid_hr_idx) * tr_partition / 100)+1:end);
	test_win_idx = [ts_idx{hr1} - window_size; ts_idx{hr1} + window_size];
	test_win_idx = floor(linspaceNDim(test_win_idx(1, :), test_win_idx(2, :), window_size*2+1));
	ecg_test = ecg_data(test_win_idx)';

	if variable_window
		ecg_train = window_and_interpolate(ecg_train, floor(estimated_hr(tr_idx{hr1})), window_size);
		ecg_test = window_and_interpolate(ecg_test, floor(estimated_hr(ts_idx{hr1})), window_size);
	end
	train_peak_heights = ecg_train(window_size+1, :);
	test_peak_heights = ecg_test(window_size+1, :);
	if normalize
		ecg_train = bsxfun(@rdivide, bsxfun(@minus, ecg_train, mean(ecg_train, dimm)), std(ecg_train, [], dimm));
		ecg_test = bsxfun(@rdivide, bsxfun(@minus, ecg_test, mean(ecg_test, dimm)), std(ecg_test, [], dimm));
		% ecg_train = bsxfun(@minus, ecg_train, mean(ecg_train, dimm));
		% ecg_test = bsxfun(@minus, ecg_test, mean(ecg_test, dimm));
	end

	if sparse_code_peaks
		param.mode = 2;
		train_alpha{hr1} = mexLasso(ecg_train, D, param);
		test_alpha{hr1} = mexLasso(ecg_test, D, param);
		if add_summ_diff
			train_alpha{hr1} = [train_alpha{hr1}; sum(abs(ecg_train - (D * train_alpha{hr1})))];
			test_alpha{hr1} = [test_alpha{hr1}; sum(abs(ecg_test - (D * test_alpha{hr1})))];
			% train_alpha{hr1} = [train_alpha{hr1}; sum(ecg_train - D * train_alpha{hr1})];
			% test_alpha{hr1} = [test_alpha{hr1}; sum(ecg_test - D * test_alpha{hr1})];
		end
		if add_all_diff
			train_alpha{hr1} = [train_alpha{hr1}; (abs(ecg_train - (D * train_alpha{hr1})))];
			test_alpha{hr1} = [test_alpha{hr1}; (abs(ecg_test - (D * test_alpha{hr1})))];
		end
		if add_height
			train_alpha{hr1} = [train_alpha{hr1}; train_peak_heights];
			test_alpha{hr1} = [test_alpha{hr1}; test_peak_heights];
		end
	else
		train_alpha{hr1} = ecg_train;
		test_alpha{hr1} = ecg_test;
	end
	
	ecg_train_Y{hr1} = peak_labels(tr_idx{hr1});
	ecg_test_Y{hr1} = peak_labels(ts_idx{hr1});

	% sparse_coding_plots(2, param.K, D);
	sparse_coding_plots(3, ecg_test, ecg_test_Y{hr1}, test_alpha{hr1}, D, 'ts');
	keyboard
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function[ecg_samples] = window_and_interpolate(ecg_samples, hr_to_resize, window_size)

% The lower bound 30.3237 comes from taking the slope of the within RT distance
varying_windows = floor(linspace(50, 30.3237, 151));
hr_range = floor(linspace(70, 140, 151));
mid_point = floor(window_size+1);
assert(isequal(size(ecg_samples, 2), size(hr_to_resize, 2)));

for i = 1:size(hr_to_resize, 2)
	varying_window_entry = varying_windows(find(hr_range == hr_to_resize(i)));
	assert(~isempty(varying_window_entry));
	one_half = floor(varying_window_entry/2);
	new_window = mid_point-one_half:mid_point+one_half;
	new_wini = linspace(1, length(new_window), window_size*2+1);
	ecg_samples(:, i) = interp1(1:length(new_window), ecg_samples(new_window, i), new_wini, 'pchip');
end

%{
% train_alpha{hr1} = [train_alpha{hr1}; sum(ecg_train - D * train_alpha{hr1})];
% test_alpha{hr1} = [test_alpha{hr1}; sum(ecg_test - D * test_alpha{hr1})];
a = sum(abs(ecg_test) - abs(D * test_alpha{hr1}));
b = sum(ecg_test - D * test_alpha{hr1});
figure();
set(gcf, 'Position', get_project_settings('figure_size'));
label_str = {'P', 'Q', 'R', 'S', 'T', 'U'};
for l = 1:6
	subplot(2, 3, l);
	hist(a(find(ecg_test_Y{hr1} == l)));
	hold on; hist(b(find(ecg_test_Y{hr1} == l)));
	plot(mean(a(find(ecg_test_Y{hr1} == l))), 2, 'go', 'MarkerFaceColor', 'g');
	plot(mean(b(find(ecg_test_Y{hr1} == l))), 2, 'ro', 'MarkerFaceColor', 'r');
	h = findobj(gca, 'Type', 'patch');
	set(h(1), 'FaceColor', [166, 42, 42] ./ 255, 'FaceAlpha', 0.40);
	set(h(2), 'FaceColor', [46, 139, 87] ./ 255, 'FaceAlpha', 0.40);
	xlim([-0.2, 0.2]); xlabel('feature vals'); ylabel('count');
	title(sprintf('%s', label_str{l}));
end
legend('abs sum', 'sum only');
image_format = get_project_settings('image_format');
file_name = sprintf('/home/anataraj/NIH-craving/plots/sparse_coding/misc_plots/%d_diff_feat', hr1);
savesamesize(gcf, 'file', file_name, 'format', image_format);
%}

