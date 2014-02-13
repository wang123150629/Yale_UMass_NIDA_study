function[train_alpha, ecg_train_Y, tr_idx, test_alpha,...
	ecg_test_Y, ts_idx, learn_alpha, ln_idx, ecg_data, hr_bins] =...
						load_hr_ecg(first_baseline_subtract, sparse_code_peaks, variable_window,...
						normalize, add_height, add_summ_diff, add_all_diff, subject_id, lambda,...
						data_split, dimm, analysis_id, filter_size, partition_train_set)

results_dir = get_project_settings('results');

window_size = 25;
clusters_apart = get_project_settings('clusters_apart');
% Checking if window size is odd
assert(mod(window_size, 2) > 0);
tr_partition = 50;
nDictionayElements = 100;
nIterations = 1000;
h = fspecial('gaussian', [1, filter_size], 150);
h = h / sum(h);
time_matrix = [];

% P20_040 - Six labels P, Q, R, S, T, U - Unknown; only chunk of cocaine day from 1 to 3pm
% load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_new_labels.mat', subject_id)));
% P20_040 - New file : Six labels P, Q, R, S, T, U - Unknown; the whole cocaine day. Refer to check_peaks.m
% QTDB Records - Labels are matched as per ECGPUwave predictions. Refer to qtdb_subj.m
load(fullfile(results_dir, 'labeled_peaks', sprintf('%s_grnd_trth.mat', subject_id)));
% The last entry is a pair of empty ""
% time_matrix = time_matrix(1, 1:end-1);
% time_matrix = time_matrix(1, filter_size/2:end-filter_size/2);
switch subject_id
case 'P20_040'
	magic_idx = get_project_settings('magic_idx', subject_id);
	labeled_peaks = labeled_peaks(:, magic_idx);
end

% Reading off data from the interface file
ecg_raw = labeled_peaks(1, :);
if first_baseline_subtract
	% Performing baseline correction
	ecg_data = ecg_raw - conv(ecg_raw, h, 'same');
else
	ecg_data = ecg_raw;
end
ecg_data = ecg_data(filter_size/2:end-filter_size/2);

peak_idx = labeled_peaks(3, :) > 0;
peak_idx = peak_idx(filter_size/2:end-filter_size/2);
peak_idx(1, [1:window_size, end-window_size:end]) = 0;

labeled_idx = labeled_peaks(3, :) > 0 & labeled_peaks(3, :) < 100;
labeled_idx = labeled_idx(filter_size/2:end-filter_size/2);
labeled_idx(1, [1:window_size, end-window_size:end]) = 0;

peak_labels = labeled_peaks(3, :);
peak_labels = peak_labels(filter_size/2:end-filter_size/2);

% Finding which of those peaks are in fact hand labelled
labeled_peaks_idx = peak_idx & labeled_idx;

estimated_hr = ones(size(ecg_data)) * -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Computing the HR for each of the peaks (NOTE: Now all peaks are associated with a HR; NOT just labelled peaks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This mat holds the new range 70 to 140
% load('/home/anataraj/NIH-craving/results/labeled_peaks/assigned_hr_bl_subtract_sgram_071313.mat');
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

switch data_split
case 'unf_spt'
	estimated_hr(peak_idx) = assigned_hr;
	nBins = 3;
	tmp_valid_hr = estimated_hr(estimated_hr > 0);
	binned_hr = ntile_split(tmp_valid_hr, nBins);
	for b = 1:nBins
		hr_bins(b, :) = [min(tmp_valid_hr(binned_hr{b})), max(tmp_valid_hr(binned_hr{b}))];
	end
case 'hrd_spt'
	estimated_hr(peak_idx) = assigned_hr;
	hr_bins = [50, 99; 100, 119; 120, 250];
case 'two_prt'
	% Hard coding all valid peaks to have a heart rate of 100 so it gets through the 40 to 250 range filter
	estimated_hr(peak_idx) = 100;
	hr_bins = [40, 250];
end

for hr1 = 1:size(hr_bins, 1)
	unlabeled_idx = find(peak_idx - labeled_idx);
	assert(~isempty(unlabeled_idx));
	ln_idx{hr1} = unlabeled_idx;

	% Training instances. Finding which of the hand labelled peaks fall within the valid HR range
	valid_hr_idx = estimated_hr >= hr_bins(hr1, 1) & estimated_hr <= hr_bins(hr1, 2);
	valid_hr_idx = find(valid_hr_idx & labeled_peaks_idx);
	valid_clusters = [0, find(diff(valid_hr_idx) > clusters_apart)];

	switch partition_train_set
	case 1, ordered_valid_clusters = 1:length(valid_clusters);
	case 2, ordered_valid_clusters = randperm(length(valid_clusters));
	otherwise, error('Invalid partition flag!');
	end

	% Train and test clusters will have a number between 1 and 93
	train_clusters = ordered_valid_clusters(1:floor(length(valid_clusters) * tr_partition / 100));
	test_clusters = ordered_valid_clusters(floor(length(valid_clusters) * tr_partition / 100)+1:end);
	valid_clusters = [valid_clusters, length(valid_hr_idx)];

	tr_temp_idx = [];
	for tr = 1:length(train_clusters)
		% By indexing into train_cluster(tr) I get a number between 1 and 93 say 5. At position 5 in the valid_cluster
		% there is an index 49 sitting. This 49 is where a cluster actually ends hence valid_clusters(49)+1 will give us
		% the first peak in the next cluster. For the end of the cluster we use valid_clusters(49+1) = valid_clusters(50)
		% summary: valid_clusters(49)+1:valid_clusters(50) i.e. 1162+1:1184 == 1163:1184. Recall valid_hr_idx is just
		% the location of all labelled peaks
		tr_temp_idx = [tr_temp_idx, valid_hr_idx(valid_clusters(train_clusters(tr))+1:valid_clusters(train_clusters(tr)+1))];
	end
	tr_idx{hr1} = sort(tr_temp_idx); % valid_hr_idx(1:floor(length(valid_hr_idx) * tr_partition / 100));
	assert(isequal(sum(diff(tr_idx{hr1}) > clusters_apart)+1, length(train_clusters)));

	ts_temp_idx = [];
	for ts = 1:length(test_clusters)
		ts_temp_idx = [ts_temp_idx, valid_hr_idx(valid_clusters(test_clusters(ts))+1:valid_clusters(test_clusters(ts)+1))];
	end
	ts_idx{hr1} = sort(ts_temp_idx); % valid_hr_idx(floor(length(valid_hr_idx) * tr_partition / 100)+1:end);
	assert(isequal(sum(diff(ts_idx{hr1}) > clusters_apart)+1, length(test_clusters)));

	assert(isequal(length(tr_idx{hr1}) + length(ts_idx{hr1}), length(valid_hr_idx)));

	unlabeled_idx = [unlabeled_idx - window_size; unlabeled_idx + window_size];
	unlabeled_idx = floor(linspaceNDim(unlabeled_idx(1, :), unlabeled_idx(2, :), window_size*2+1));
	ecg_learn = ecg_data(unlabeled_idx)';

	train_win_idx = [tr_idx{hr1} - window_size; tr_idx{hr1} + window_size];
	train_win_idx = floor(linspaceNDim(train_win_idx(1, :), train_win_idx(2, :), window_size*2+1));
	ecg_train = ecg_data(train_win_idx)';

	test_win_idx = [ts_idx{hr1} - window_size; ts_idx{hr1} + window_size];
	test_win_idx = floor(linspaceNDim(test_win_idx(1, :), test_win_idx(2, :), window_size*2+1));
	ecg_test = ecg_data(test_win_idx)';

	if variable_window
		ecg_learn = window_and_interpolate(ecg_learn, floor(estimated_hr(find(peak_idx - labeled_idx))), window_size);
		ecg_train = window_and_interpolate(ecg_train, floor(estimated_hr(tr_idx{hr1})), window_size);
		ecg_test = window_and_interpolate(ecg_test, floor(estimated_hr(ts_idx{hr1})), window_size);
	end
	train_peak_heights = ecg_train(window_size+1, :);
	test_peak_heights = ecg_test(window_size+1, :);
	learn_peak_heights = ecg_learn(window_size+1, :);

	switch normalize
	case 1
		ecg_learn = bsxfun(@rdivide, bsxfun(@minus, ecg_learn, mean(ecg_learn, dimm)), std(ecg_learn, [], dimm));
		ecg_train = bsxfun(@rdivide, bsxfun(@minus, ecg_train, mean(ecg_train, dimm)), std(ecg_train, [], dimm));
		ecg_test = bsxfun(@rdivide, bsxfun(@minus, ecg_test, mean(ecg_test, dimm)), std(ecg_test, [], dimm));
	case 2
		ecg_learn = bsxfun(@minus, ecg_learn, mean(ecg_learn, dimm));
		ecg_train = bsxfun(@minus, ecg_train, mean(ecg_train, dimm));
		ecg_test = bsxfun(@minus, ecg_test, mean(ecg_test, dimm));
	case 3
		pooled_std = std([reshape(ecg_learn, 1, size(ecg_learn, 1) * size(ecg_learn, 2)),...
				     reshape(ecg_train, 1, size(ecg_train, 1) * size(ecg_train, 2)),...
				     reshape(ecg_test, 1, size(ecg_test, 1) * size(ecg_test, 2))]);
		assert(pooled_std > 0);
		ecg_learn = bsxfun(@rdivide, bsxfun(@minus, ecg_learn, mean(ecg_learn, dimm)), pooled_std);
		ecg_train = bsxfun(@rdivide, bsxfun(@minus, ecg_train, mean(ecg_train, dimm)), pooled_std);
		ecg_test = bsxfun(@rdivide, bsxfun(@minus, ecg_test, mean(ecg_test, dimm)), pooled_std);
	end
	assert(isequal(size(ecg_learn, 1), size(ecg_train, 1)));
	assert(isequal(size(ecg_learn, 1), size(ecg_test, 1)));

	if sparse_code_peaks
		param = struct();
		param.K = nDictionayElements;  % learns a dictionary with 100 elements
		param.iter = nIterations;  % let us see what happens after 1000 iterations
		param.lambda = lambda;
		param.numThreads = 4; % number of threads
		param.batchsize = 400;
		param.approx = 0;
		param.verbose = false;
		param.mode = 2;

		D = mexTrainDL(ecg_learn, param);
		% sparse_coding_plots(2, param.K, D, analysis_id);

		learn_alpha{hr1} = mexLasso(ecg_learn, D, param);
		train_alpha{hr1} = mexLasso(ecg_train, D, param);
		test_alpha{hr1} = mexLasso(ecg_test, D, param);
		ecg_test_reconstructions{hr1} = test_alpha{hr1}' * D';
		ecg_test_originals{hr1} = ecg_test';

		if add_summ_diff
			learn_alpha{hr1} = [learn_alpha{hr1}; sum(abs(ecg_learn - (D * learn_alpha{1})))];
			train_alpha{hr1} = [train_alpha{hr1}; sum(abs(ecg_train - (D * train_alpha{hr1})))];
			test_alpha{hr1} = [test_alpha{hr1}; sum(abs(ecg_test - (D * test_alpha{hr1})))];
			% learn_alpha{hr1} = [learn_alpha{1}; sum(ecg_learn - D * learn_alpha{1})];
			% train_alpha{hr1} = [train_alpha{hr1}; sum(ecg_train - D * train_alpha{hr1})];
			% test_alpha{hr1} = [test_alpha{hr1}; sum(ecg_test - D * test_alpha{hr1})];
		end

		if add_all_diff
			learn_alpha{hr1} = [learn_alpha{hr1}; (abs(ecg_learn - (D * learn_alpha{1})))];
			train_alpha{hr1} = [train_alpha{hr1}; (abs(ecg_train - (D * train_alpha{hr1})))];
			test_alpha{hr1} = [test_alpha{hr1}; (abs(ecg_test - (D * test_alpha{hr1})))];
		end

		switch add_height
		case 1
			learn_alpha{hr1} = [learn_alpha{hr1}; learn_peak_heights];
			train_alpha{hr1} = [train_alpha{hr1}; train_peak_heights];
			test_alpha{hr1} = [test_alpha{hr1}; test_peak_heights];
		case 2
			learn_alpha{hr1} = [learn_alpha{hr1};...
					    learn_peak_heights; learn_peak_heights.^2; ones(size(learn_peak_heights))];
			train_alpha{hr1} = [train_alpha{hr1};...
					    train_peak_heights; train_peak_heights.^2; ones(size(train_peak_heights))];
			test_alpha{hr1} = [test_alpha{hr1};...
					    test_peak_heights; test_peak_heights.^2; ones(size(test_peak_heights))];
		end
	else
		learn_alpha{hr1} = ecg_learn;
		train_alpha{hr1} = ecg_train;
		test_alpha{hr1} = ecg_test;
	end
	assert(isequal(size(learn_alpha{1}, 1), size(train_alpha{1}, 1)));
	assert(isequal(size(learn_alpha{1}, 1), size(test_alpha{1}, 1)));

	ecg_train_Y{hr1} = peak_labels(tr_idx{hr1});
	ecg_test_Y{hr1} = peak_labels(ts_idx{hr1});

	%{
	% Plots for Ben's 15 min presentation
	% sparse_coding_plots(3, ecg_test, ecg_test_Y{hr1}, test_alpha{hr1}, D, sprintf('%s_ts', analysis_id));
	orig_ecg = ecg_data(test_win_idx)';
	varwin_ecg = window_and_interpolate(orig_ecg, floor(estimated_hr(ts_idx{hr1})), window_size);
	temp_dimm = 1;
	orig_norm_ecg = bsxfun(@rdivide, bsxfun(@minus, orig_ecg, mean(orig_ecg, temp_dimm)), std(orig_ecg, [], temp_dimm));
	varwin_norm_ecg = bsxfun(@rdivide, bsxfun(@minus, varwin_ecg, mean(varwin_ecg, temp_dimm)), std(varwin_ecg, [], temp_dimm));
	temp_dimm = 2;
	orig_norm2_ecg = bsxfun(@rdivide, bsxfun(@minus, orig_ecg, mean(orig_ecg, temp_dimm)), std(orig_ecg, [], temp_dimm));
	varwin_norm2_ecg = bsxfun(@rdivide, bsxfun(@minus, varwin_ecg, mean(varwin_ecg, temp_dimm)), std(varwin_ecg, [], temp_dimm));
	sparse_coding_plots(15, orig_ecg, orig_norm_ecg, orig_norm2_ecg, varwin_ecg, varwin_norm_ecg, varwin_norm2_ecg,...
				ecg_test_Y{hr1}, hr1, analysis_id);
	%}
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

